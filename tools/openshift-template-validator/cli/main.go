package cli

import (
	"fmt"
	"os"
	"sort"
	"time"

	"github.com/urfave/cli"
)

// project version
var version = "0.1-dev"

func init() {
	cli.VersionFlag = cli.BoolFlag{Name: "version, V"}
	cli.VersionPrinter = func(c *cli.Context) {
		fmt.Fprintf(c.App.Writer, "openshift-template-validator version %s\n", version)
	}
}

func Execute() {
	app := cli.NewApp()
	app.Name = "openshift-template-validator"
	app.Usage = "Validate your OpenShift Application Templates, easier than never."
	app.Version = version
	app.Compiled = time.Now()
	app.Email = "bsig-cloud@redhat.com"

	// Commands
	app.Commands = []cli.Command{
		validateCommand,
	}
	sort.Sort(cli.FlagsByName(app.Flags))
	sort.Sort(cli.CommandsByName(app.Commands))
	app.Run(os.Args)
}
