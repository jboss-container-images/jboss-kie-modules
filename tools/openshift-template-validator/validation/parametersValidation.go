package validation

import (
	"bufio"
	"fmt"
	"github.com/asaskevich/govalidator"
	"github.com/openshift/origin/pkg/api/legacygroupification"
	"gopkg.in/yaml.v2"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"os"
	"regexp"
	"strconv"
	"strings"

	appsapiv1 "github.com/openshift/api/apps/v1"
	"k8s.io/kubernetes/pkg/api/legacyscheme"

	"github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator/utils"
	templateapi "github.com/openshift/origin/pkg/template/apis/template"
	"k8s.io/apimachinery/pkg/runtime"
)

func init() {
	govalidator.SetFieldsRequiredByDefault(true)
}

type Parameter struct {
	Parameters []struct {
		DisplayName string `yaml:"displayName" valid:"required~Parameter field displayName is empty"`
		Description string `yaml:"description" valid:"required~Parameter field description is empty"`
		Name        string `yaml:"name" valid:"required~Parameter field name is empty"`
		Required    string `yaml:"required" valid:"required~Parameter field 'required' is empty"`
		Value       string `yaml:"value" valid:"-"`
		From        string `yaml:"from" valid:"-"`
		Generate    string `yaml:"generate" valid:"-"`
		Example     string `yaml:"example" valid:"-"`
	} `yaml:"parameters"`
}

func validateTemplateParameters(parameters []templateapi.Parameter, file string, extension string, objects []runtime.Object) {

	var parameterValidationErrors []string
	var param Parameter
	var item string

	if extension == "yaml" {
		begin, end := parametersLines(file)
		count := 0
		fileContent, _ := os.Open(file)
		scanner := bufio.NewScanner(fileContent)

		for scanner.Scan() {
			line := scanner.Text()
			count++
			if count > begin && count < end && !strings.HasPrefix(line, "#") {
				item += "\n" + line

			}
		}

	} else if strings.HasSuffix(extension, "json") {
		// convert json to yaml
		if len(parameters) > 0 {
			var pValues = "parameters:\n"
			for _, p := range parameters {
				description := strings.Replace(p.Description, "\"", "", -1)
				pValues += "- displayName: " + p.DisplayName + "\n" +
					"  description: \"" + description + "\"\n" +
					"  name: " + p.Name + "\n" +
					"  required: " + strconv.FormatBool(p.Required) + "\n" +
					"  value: " + p.Value + "\n" +
					"  from: \"" + p.From + "\"\n" +
					"  generate: " + p.Generate + "\n" +
					"  example: \n"
			}
			item = pValues
		}

	} else {
		validationErrors["Extension"] = append(validationErrors["Extension"], "Extension "+extension+" not supported.")
	}

	if utils.DumpParameters {
		fmt.Println(item)
	}

	if err := yaml.UnmarshalStrict([]byte(item), &param); err != nil && utils.Debug {
		fmt.Println("\nWarning: " + err.Error())
	}

	for index, param := range param.Parameters {
		if _, err := govalidator.ValidateStruct(param); err != nil {
			var field string
			if param.Name == "" {
				field = param.DisplayName
			} else {
				field = param.Name
			}
			parameterValidationErrors = append(parameterValidationErrors, "Index ["+strconv.Itoa(index+1)+"] Parameter name "+field+" - "+err.Error()+"; ")
		}
	}

	if len(parameterValidationErrors) > 0 {
		validationErrors["Parameters"] = append(validationErrors["Parameters"], strings.Join(parameterValidationErrors, ""))
	}

	// get the unprocessed template objects, this way we can assure that all Envs contains the name, and in the value field
	// Example:
	//  	 - name: KIE_ADMIN_USER
	//         value: "${KIE_ADMIN_USER}"
	// we get something like: {v1.EnvVar{Name:"KIE_ADMIN_USER", Value:"${KIE_ADMIN_USER}"
	// this we can compare if all parameters are being in used somewhere in the env
	envsMap := make(map[string]string)
	var envValues string
	for _, item := range objects {
		if obj, ok := item.(*runtime.Unknown); ok {
			decodedObj, _ := runtime.Decode(unstructured.UnstructuredJSONScheme, obj.Raw)
			item = decodedObj
		}
		gvk := item.GetObjectKind().GroupVersionKind()
		legacygroupification.OAPIToGroupifiedGVK(&gvk)
		item.GetObjectKind().SetGroupVersionKind(gvk)
		unstructuredObj := item.(*unstructured.Unstructured)

		obj, err := legacyscheme.Scheme.New(unstructuredObj.GroupVersionKind())
		if err != nil {
			fmt.Printf("Error on creating new Unstructured object %v\n", err.Error())
		}
		runtime.DefaultUnstructuredConverter.FromUnstructured(unstructuredObj.Object, obj)

		switch t := obj.(type) {
		case *appsapiv1.DeploymentConfig:
			// only get name/value

			for _, container := range t.Spec.Template.Spec.Containers {
				for _, env := range container.Env {
					replacer := strings.NewReplacer("$", "", "{", "", "}","")
					envsMap[env.Name] = "dummy"
					envValues += replacer.Replace(env.Value) + "-"
				}
			}
		}
	}

	// usually envs that contains the following pattern in the name is not used under container envs.
	r, _ := regexp.Compile(`EXTENSIONS_IMAGE|APPLICATION_NAME|HTTPS_SECRET|IMAGE_STREAM|VOLUME_CAPACITY$|MEMORY_LIMIT$|HOSTNAME_HTTP|SOURCE_REPOSITORY|WEBHOOK_SECRET|_DIR$|MAVEN_MIRROR_URL`)
	for _, parameter := range parameters {
		// check if the parameter.Name is present on envs map
		_, present := envsMap[parameter.Name]
		if !present && !strings.Contains(envValues, parameter.Name) {
			// make sure that the parameter is not used as value too.
			if !r.MatchString(parameter.Name) {
				validationErrors["Parameters"] = append(validationErrors["Parameters"], "Parameter ["+parameter.Name+"] is defined but is not used in any container envs.")
			}
		}
	}
}

// returns line number where the parameters starts/ends
func parametersLines(file string) (begin int, end int) {
	target, err := os.Open(file)
	if err != nil {
		fmt.Println(err)
	}
	defer target.Close()

	scanner := bufio.NewScanner(target)
	var counter int
	for scanner.Scan() {
		counter++
		if strings.Contains(scanner.Text(), "parameters:") {
			begin = counter - 1
		}
		if strings.Contains(scanner.Text(), "objects:") {
			end = counter
		}

	}
	return begin, end
}
