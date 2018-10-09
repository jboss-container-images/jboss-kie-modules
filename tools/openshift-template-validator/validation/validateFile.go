package validation

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path"
	"path/filepath"
	"strings"

	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/util/yaml"
	"k8s.io/kubernetes/pkg/api/legacyscheme"

	templateapi "github.com/openshift/origin/pkg/template/apis/template"

	"github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator/utils"

	_ "github.com/openshift/origin/pkg/api/install"
)

var (
	// store the template extension, supported values are yaml or json
	templateExtension string

	// map to store the errors found during the template validation, every error found will be printed at the end of the
	// the execution
	validationErrors = make(map[string][]string)
)

// main validate function, everything starts here.
func Validate(file string) bool {

	var containValidationErrors bool

	if _, err := os.Stat(file); os.IsNotExist(err) {
		fmt.Println(err.Error())
		os.Exit(10)
	} else {

		var template templateapi.Template

		templateExtension = filepath.Ext(file)
		data, err := utils.ReadFile(file)

		// if yaml convert to json
		if templateExtension == ".yaml" {
			templateExtension = "yaml"
			data, err = yaml.ToJSON(data)
			if err != nil {
				fmt.Printf("Issue parsing from yaml to json: %v", err.Error())
			}

			// users can specify the persist flag to save a copy of the json formatted file on /tmp/<filename>.json
			if utils.Persist && templateExtension == "yaml" {
				ioutil.WriteFile(path.Join("/tmp/", strings.Replace(filepath.Base(file), "yaml", "json", 1)), data, 0644)
			}
		}

		fmt.Print("Validating file " + file)
		// replace the very first apiVersion from v1 to template.openshift.io/v1
		if utils.Debug {
			fmt.Print(" -> replacing Template apiVersion from v1 to template.openshift.io/v1")
		}
		data = bytes.Replace(data, []byte("v1"), []byte("template.openshift.io/v1"), 1)

		// global validator, only verifies syntax issues
		if err := runtime.DecodeInto(legacyscheme.Codecs.UniversalDecoder(), data, &template); err != nil {
			validationErrors["Syntax"] = append(validationErrors["Syntax"], filepath.Base(file)+" - "+err.Error())
		}

		// parse the data to json
		if err := json.Unmarshal(data, &template); err != nil {
			validationErrors["JSON_Parser"] = append(validationErrors["JSON_Parser"], filepath.Base(file)+" - "+err.Error())

			// ignore other kinds
		} else if template.Kind == "Template" { // do the other validations

			// validate the template annotations
			validateAnnotations(template.Annotations, template.Name)

			// validate template name, should not be empty and should be equal to the label "template"
			validateTemplateName(template.Name, template.Labels)

			// validate template parameters
			//		all templates should have the same required fields: displayName, description, name
			validateTemplateParameters(template.Parameters, file, templateExtension, template.Objects)

			// validate all template objects like, DeploymentConfig, BuildConfig, ImageStreams, Rolebinding, etc..
			validateObjects(template)

		}

		if len(validationErrors) > 0 {
			fmt.Print("\nErrors found: ")
			utils.JSONPrettyPrint(validationErrors)
			// clean the env to store the report of the next validation (if the target is a subset of templates)
			validationErrors = make(map[string][]string)
			containValidationErrors = true
		} else {
			fmt.Println(" -----> No validation issues found.")
			containValidationErrors = false
		}

	}
	return containValidationErrors
}

// template name and label template should be the same, example:
// kind: Template
// apiVersion: v1
// metadata:
// ...
//   name: rhdm71-full-persistent
// labels:
//  template: rhdm71-full-persistent
func validateTemplateName(templateName string, templateLabels map[string]string) {
	if (templateName == "" && templateLabels["template"] == "") || (templateName != templateLabels["template"]) {
		validationErrors["Template_Name"] = append(validationErrors["Template_Name"], "Template name/template label are empty or not equal")
	}
}
