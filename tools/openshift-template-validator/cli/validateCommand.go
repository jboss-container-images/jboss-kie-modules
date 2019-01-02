package cli

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator/utils"
	"github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator/validation"
	"github.com/urfave/cli"
)

var ValidateCommand = cli.Command{
	Name:        "validate",
	Usage:       "Validate OpenShift Application Template(s)",
	Description: "Validate just one template or a bunch of them, the issues found will be printed, the binary will exit with 0, means success and any value different than 0 means that some issue happened (10 - file or directory not found, 12 - validation issues, 15 - panic)",
	Flags: []cli.Flag{
		cli.StringFlag{
			Name:        "file, f",
			Usage:       "Set the template or imagestream to be validate, can be a local file or a remote valid url with raw content.",
			Destination: &utils.File,
		},
		cli.StringFlag{
			Name:        "dir, d",
			Usage:       "Define a directory to be read, all yaml and json files in the given directory will be validated by the tool.",
			Destination: &utils.LocalDir,
		},
		cli.BoolFlag{
			Name:        "persist, p",
			Usage:       "If set, the validated yaml file be saved on /tmp/<file-name> in the json format.",
			Destination: &utils.Persist,
		},
		cli.StringFlag{
			Name:        "custom-annotation, a",
			Usage:       "Define a custom annotation to be tested against the target template's annotations, values must be separated by comma ',' with no spaces. The default annotations are [" + arrayToString(utils.RequiredAnnotations) + "]",
			Destination: &utils.CustomAnnotation,
		},
		cli.StringFlag{
			Name:        "template-version, v",
			Value:       "1.2",
			Usage:       "The template version that will br tested with the target templates, if not provided.",
			Destination: &utils.ProvidedTemplateVersion,
		},
		cli.BoolFlag{
			Name:        "validate-version, V",
			Usage:       "If set, the template version will be validate.",
			Destination: &utils.ValidateTemplateVersion,
		},
		cli.BoolFlag{
			Name:        "verbose, vv",
			Usage:       "Prints detailed log messages",
			Destination: &utils.Debug,
		},
		cli.BoolFlag{
			Name:        "strict, s",
			Usage:       "Enable the strict mode, will verify if any required parameter have no value.",
			Destination: &utils.Strict,
		},
		cli.BoolFlag{
			Name:        "dump, du",
			Usage:       "Dump all parsed template parameters.",
			Destination: &utils.DumpParameters,
		},
		cli.BoolFlag{
			Name:        "disable-defer",
			Usage:       "Disable defer which recover from panic for troubleshooting purposes.",
			Destination: &utils.DisableDefer,
		},
	},
	Action: func(c *cli.Context) error {

		if len(utils.File) > 0 {
			if validation.Validate(utils.File) {
				os.Exit(12)
			}

		} else if len(utils.LocalDir) > 0 {
			if _, err := os.Stat(utils.LocalDir); os.IsNotExist(err) {
				fmt.Println(err.Error())
				os.Exit(10)
			} else {
				if walkDir(utils.LocalDir) {
					os.Exit(12)
				}
			}
		}
		return nil
	},
}

func arrayToString(array []string) string {
	return strings.Join(array, ", ")
}

func walkDir(localDir string) bool {
	var containErrors = false
	var fileRegex = regexp.MustCompile(`.yaml|json$`)
	var excludeDirRegex = regexp.MustCompile(`.git|target|tests|contrib`)
	fmt.Println("Reading directory " + localDir)
	filepath.Walk(localDir, func(absoluteFilePath string, fileInfo os.FileInfo, err error) error {

		if excludeDirRegex.MatchString(absoluteFilePath) {
			return filepath.SkipDir
		} else if !fileInfo.IsDir() {
			if fileRegex.MatchString(fileInfo.Name()) {
				if validation.Validate(absoluteFilePath) {
					containErrors = true
				}
			}
		}
		return nil
	})
	return containErrors
}
