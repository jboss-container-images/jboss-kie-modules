package validation

import (
	"bufio"
	"fmt"
	"github.com/asaskevich/govalidator"
	"gopkg.in/yaml.v2"
	"os"
	"strconv"
	"strings"

	templateapi "github.com/openshift/origin/pkg/template/apis/template"

	"github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator/utils"
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

func validateTemplateParameters(parameters []templateapi.Parameter, file string, extension string) {

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
