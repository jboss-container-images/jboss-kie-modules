package utils

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"regexp"
	"strconv"
)

// all vars that will be set depending on the parameters provided by the user on command line, for reference see cli/validateCommand.go file.
var (
	CustomAnnotation        string
	File                    string
	LocalDir                string
	ProvidedTemplateVersion string
	Debug                   bool
	DumpParameters          bool
	Persist                 bool
	Strict                  bool
	ValidateTemplateVersion bool
	RequiredAnnotations     = []string{"iconClass", "openshift.io/display-name", "tags", "version", "description", "openshift.io/provider-display-name",
		"template.openshift.io/documentation-url", "template.openshift.io/support-url", "template.openshift.io/long-description", "template.openshift.io/bindable"}
	RequiredImageStreamAnnotations = []string{"description", "iconClass", "tags", "supports", "version"}
)

// read the template and returns its raw data
func ReadFile(file string) ([]byte, error) {
	return ioutil.ReadFile(file)
}

// prints the command output as JSON
func JSONPrettyPrint(v interface{}) (err error) {
	b, err := json.MarshalIndent(v, "", "  ")
	if err == nil {
		fmt.Println(string(b))
	}
	return
}

// Parse the provided value to the annotation haproxy.router.openshift.io/timeout, value must match the regex ^[0-9]*(us|ms|s|m|h|d)$
func ParseHAProxyTimeout(value string) error {
	// remove the suffix time unit
	isValid, _ := regexp.MatchString(`^[0-9]*(us|ms|s|m|h|d)$`, value)
	rep := regexp.MustCompile(`(us|ms|s|m|h|d)`)

	if isValid {
		value = rep.ReplaceAllString(value, "")
	} else {
		return errors.New("provided value does not match the regex ^[0-9]*(us|ms|s|m|h|d)$")
	}
	_, err := strconv.Atoi(value)
	return err
}

func ParsePort(value string) error {
	_, err := strconv.Atoi(value)
	return err
}

func In_array(a []string, value string) bool {
	for _, v := range a {
		if v == value {
			return true
		}
	}
	return false
}

func RecoverFromPanic() {
	if r := recover(); r != nil {
		if Debug {
			fmt.Println("recovered from ", r)
		}
	}
}
