package main

import (
	"bytes"
	validatorcli "github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator/cli"
	"github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator/utils"
	"github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator/validation"
	"github.com/stretchr/testify/assert"
	"github.com/urfave/cli"
	"io"
	"os"
	"strings"
	"testing"
)

func TestInvalidFlag(t *testing.T) {
	oldStdout := os.Stdout
	os.Stdout = nil
	var app = cli.NewApp()
	app.Version = "test"
	app.Commands = []cli.Command{
		validatorcli.ValidateCommand,
	}
	os.Args = []string{"openshift-template-validator", "--helsp"}
	err := app.Run(os.Args)
	assert.Equal(t, err.Error(), "flag provided but not defined: -helsp")
	os.Stdout = oldStdout
}

func TestValidateTflag(t *testing.T) {
	stdout := os.Stdout
	os.Stdout = nil
	var app = cli.NewApp()
	app.Commands = []cli.Command{
		validatorcli.ValidateCommand,
	}
	os.Stdout = nil
	os.Args = []string{"openshift-template-validator", "validate", "-t"}
	err := app.Run(os.Args)
	assert.Equal(t, err.Error(), "flag needs an argument: -t")
	os.Stdout = stdout
}

func TestTemplateParameters(t *testing.T) {

	stdout := os.Stdout
	os.Stdout = nil
	var app = cli.NewApp()
	app.Commands = []cli.Command{
		validatorcli.ValidateCommand,
	}
	os.Stdout = nil

	os.Args = []string{"openshift-template-validator", "validate", "-t", "test/basic-template.yaml", "-p", "-a", "tags=jboss", "-V", "-v", "10", "-vv", "-s", "-du"}
	app.Run(os.Args)
	assert.Equal(t, "test/basic-template.yaml", utils.File)
	assert.Equal(t, true, utils.Persist)
	assert.Equal(t, "tags=jboss", utils.CustomAnnotation)
	assert.Equal(t, true, utils.ValidateTemplateVersion)
	assert.Equal(t, "10", utils.ProvidedTemplateVersion)
	assert.Equal(t, true, utils.Debug)
	assert.Equal(t, true, utils.Strict)
	assert.Equal(t, true, utils.DumpParameters)

	fileName := os.TempDir() + "/basic-template.json"
	if _, err := os.Stat(fileName); os.IsNotExist(err) {
		t.Errorf("File does not exist, %s", fileName)
	}

	os.Args = []string{"openshift-template-validator", "validate", "-d", "test/"}
	app.Run(os.Args)
	assert.Equal(t, "test/", utils.LocalDir)

	os.Stdout = stdout

}

func TestTemplateValidation(t *testing.T) {

	old := os.Stdout
	r, w, _ := os.Pipe()
	os.Stdout = w

	validation.Validate("test/basic-template.yaml")

	w.Close()
	os.Stdout = old

	var buf bytes.Buffer
	io.Copy(&buf, r)
	//fmt.Println(buf.String())

	if strings.Contains(buf.String(), "Errors found:") {
		t.Errorf("Validation failed, report: %s", buf.String())
	}

}
