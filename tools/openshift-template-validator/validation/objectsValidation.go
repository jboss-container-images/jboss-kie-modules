package validation

import (
	"fmt"
	"math/rand"
	"reflect"
	"regexp"
	"strings"
	"time"

	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/kubernetes/pkg/api/legacyscheme"
	kapi "k8s.io/kubernetes/pkg/apis/core"
	kapiv1 "k8s.io/kubernetes/pkg/apis/core/v1"
	kvalidation "k8s.io/kubernetes/pkg/apis/core/validation"
	kappsv1 "k8s.io/api/apps/v1"
	krbac "k8s.io/kubernetes/pkg/apis/rbac"
	krbacvalidation "k8s.io/kubernetes/pkg/apis/rbac/validation"

	appsapiv1 "github.com/openshift/api/apps/v1"
	authapiv1 "github.com/openshift/api/authorization/v1"
	buildapiv1 "github.com/openshift/api/build/v1"
	imageapiv1 "github.com/openshift/api/image/v1"
	routeapiv1 "github.com/openshift/api/route/v1"
	appsapi "github.com/openshift/origin/pkg/apps/apis/apps"
	appsvalidation "github.com/openshift/origin/pkg/apps/apis/apps/validation"
	authorizationapi "github.com/openshift/origin/pkg/authorization/apis/authorization"
	"github.com/openshift/origin/pkg/authorization/apis/authorization/v1"
	"github.com/openshift/origin/pkg/authorization/apis/authorization/validation"
	buildapi "github.com/openshift/origin/pkg/build/apis/build"
	buildconversion "github.com/openshift/origin/pkg/build/apis/build/v1"
	buildvalidation "github.com/openshift/origin/pkg/build/apis/build/validation"
	imageapi "github.com/openshift/origin/pkg/image/apis/image"
	imagevalidation "github.com/openshift/origin/pkg/image/apis/image/validation"
	routeapi "github.com/openshift/origin/pkg/route/apis/route"
	routevconversion "github.com/openshift/origin/pkg/route/apis/route/v1"
	routevalidation "github.com/openshift/origin/pkg/route/apis/route/validation"
	templateapi "github.com/openshift/origin/pkg/template/apis/template"
	"github.com/openshift/origin/pkg/template/generator"
	"github.com/openshift/origin/pkg/template/templateprocessing"

	"github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator/utils"
)

func validateObjects(template templateapi.Template) {
	defer utils.RecoverFromPanic()

	// Process the template to replace the env values
	generators := map[string]generator.Generator{
		"expression": generator.NewExpressionValueGenerator(rand.New(rand.NewSource(time.Now().UnixNano()))),
	}

	// necessary hack to prevent issues while processing templates when a parameter explicit requires a input
	// from end user, we don't want to validate such scenarios.
	if !utils.Strict {
		for index, param := range template.Parameters {
			if param.Value == "" && param.Name != "APPLICATION_NAME" && param.Required == true {
				template.Parameters[index].Value = "my-generated-value"
			}
		}
	}

	processor := templateprocessing.NewProcessor(generators)
	if err := processor.Process(&template); len(err) > 0 {
		for _, e := range err {
			validationErrors["ObjectsValidation-Processor"] = append(validationErrors["ObjectsValidation-Processor"], e.Error())
		}
		if utils.Debug {
			fmt.Printf("Error on ObjectsValidation-Processo Object: %v\n", err)
		}
	}

	for index, item := range template.Objects {

		if _, err := item.(*runtime.Unknown); err {
			if utils.Debug {
				fmt.Printf("Runtime.Unkown object found: %v\n", err)
			}
		} else {

			unstructuredObj := item.(*unstructured.Unstructured)

			obj, err := legacyscheme.Scheme.New(unstructuredObj.GroupVersionKind())
			if err != nil {
				if utils.Debug {
					fmt.Printf("Error on creating new Unstructured object %v\n", err.Error())
				}
				validationErrors["PreValidation"] = append(validationErrors["PreValidation"], err.Error())
			}

			if err := runtime.DefaultUnstructuredConverter.FromUnstructured(unstructuredObj.Object, obj); err != nil {
				error := fmt.Sprintf("PreValidation-%d-%s", index, reflect.TypeOf(obj).String())
				validationErrors[error] = append(validationErrors[error], err.Error())
				if utils.Debug {
					fmt.Printf("\nError on converting Unstructured object %v\n", err.Error())
				}
			}

			switch t := obj.(type) {

			case *corev1.ServiceAccount:
				t.Namespace = "default"

				invalidApplicationLabel, _ := regexp.MatchString(`\${\w+}`, t.Labels["application"])
				if t.Labels["application"] == "" || invalidApplicationLabel {
					validationErrors["ServiceAccount"] = append(validationErrors["ServiceAccount"], "metadata.labels.application cannot be empty or value is invalid. ValueReceived="+t.Labels["application"]+".")
				}

				coreServiceAccount := &kapi.ServiceAccount{}
				kapiv1.Convert_v1_ServiceAccount_To_core_ServiceAccount(t, coreServiceAccount, nil)
				if err := kvalidation.ValidateServiceAccount(coreServiceAccount); len(err) > 0 {
					for _, e := range err {
						validationErrors["ServiceAccount"] = append(validationErrors["ServiceAccount"], e.Error())
					}
				}


			case *corev1.PersistentVolumeClaim:
				t.Namespace = "default"
				if t.Labels["application"] == "" {
					validationErrors["PersistentVolumeClaim"] = append(validationErrors["PersistentVolumeClaim"], "metadata.labels.application cannot be empty.")
				}

				corePersistentVolumeClaim := &kapi.PersistentVolumeClaim{}
				kapiv1.Convert_v1_PersistentVolumeClaim_To_core_PersistentVolumeClaim(t, corePersistentVolumeClaim, nil)
				if err := kvalidation.ValidatePersistentVolumeClaim(corePersistentVolumeClaim); len(err) > 0 {
					for _, e := range err {
						validationErrors["PersistentVolumeClaim"] = append(validationErrors["PersistentVolumeClaim"], e.Error())
					}
				}

			case *authapiv1.RoleBinding:
				t.Namespace = "default"
				authorizationRoleBinding := &authorizationapi.RoleBinding{}
				v1.Convert_v1_RoleBinding_To_authorization_RoleBinding(t, authorizationRoleBinding, nil)
				if err := validation.ValidateRoleBinding(authorizationRoleBinding, true); len(err) > 0 {
					for _, e := range err {
						validationErrors["RoleBinding"] = append(validationErrors["RoleBinding"], e.Error())
					}
				}
				if t.Labels["application"] == "" {
					validationErrors["RoleBinding"] = append(validationErrors["RoleBinding"], "metadata.labels.[application] cannot be empty.")
				}

			case *corev1.Service:
				t.Namespace = "default"
				errorPrefix := fmt.Sprintf("Service-%s", t.Name)

				// if empty, set default values for protocol, spec.sessionAffinity and spec.type
				for index, port := range t.Spec.Ports {
					if port.Protocol == "" {
						t.Spec.Ports[index].Protocol = corev1.ProtocolTCP
					}
				}
				if t.Spec.Type == "" {
					t.Spec.Type = corev1.ServiceTypeClusterIP
				}
				if t.Spec.SessionAffinity == "" {
					t.Spec.SessionAffinity = corev1.ServiceAffinityNone
				}

				coreService := &kapi.Service{}
				kapiv1.Convert_v1_Service_To_core_Service(t, coreService, nil)

				if err := kvalidation.ValidateService(coreService); len(err) > 0 {
					for _, e := range err {
						validationErrors[errorPrefix] = append(validationErrors[errorPrefix], e.Error())
					}
				}

				if t.Spec.Selector["deploymentConfig"] == "" {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "spec.selector.[deploymentConfig] is a required field")
				}

				if t.ObjectMeta.Labels["application"] == "" {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "metadata.labels.[application] cannot be empty.")
				}

				if t.ObjectMeta.Annotations["description"] == "" {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "metadata.annotations.[description] cannot be empty.")
				}

				// all ports must be integer, t.spec.port is validate, but t.spec.port.targetPort no
				for idx, port := range t.Spec.Ports {
					if port.TargetPort.StrVal != "" {
						if err := utils.ParsePort(port.TargetPort.StrVal); err != nil {
							out := fmt.Sprintf("spec.ports[%d] - %v", idx, err)
							validationErrors[errorPrefix] = append(validationErrors[errorPrefix], out)
						}
					}
				}

			case *routeapiv1.Route:
				t.Namespace = "default"
				errorPrefix := fmt.Sprintf("Route-%s", t.Name)

				// if spec.to.kind is empty, default to Service
				if t.Spec.To.Kind == "" {
					t.Spec.To.Kind = "Service"
				}

				routeRoute := &routeapi.Route{}
				routevconversion.Convert_v1_Route_To_route_Route(t, routeRoute, nil)

				if err := routevalidation.ValidateRoute(routeRoute); len(err) > 0 {
					for _, e := range err {
						validationErrors[errorPrefix] = append(validationErrors[errorPrefix], e.Error())
					}
				}

				if t.ObjectMeta.Labels["application"] == "" {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "metadata.labels.[application] cannot be empty.")
				}
				if t.ObjectMeta.Annotations["description"] == "" {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "metadata.annotations.[description] cannot be empty.")
				}
				if t.Spec.Host != "" {
					if err := routevalidation.ValidateRoute(routeRoute); err != nil {
						for _, e := range err {
							validationErrors[errorPrefix] = append(validationErrors[errorPrefix], e.Error())
						}
					}
				}

				// the haproxy.timeout is required for rhdm/pam central otherwise OpenShift router will drop the connection
				if strings.Contains(t.Name, "rhdmcentr") || strings.Contains(t.Name, "rhpamcentr") {
					if t.ObjectMeta.Annotations["haproxy.router.openshift.io/timeout"] == "" {
						validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "metadata.annotations.[haproxy.router.openshift.io/timeout] cannot be empty.")
					} else {
						// try to parse the provided value
						value := t.ObjectMeta.Annotations["haproxy.router.openshift.io/timeout"]
						err := utils.ParseHAProxyTimeout(value)
						if err != nil {
							out := fmt.Sprintf("haproxy.router.openshift.io/timeout: %s - %s", value, err.Error())
							validationErrors[errorPrefix] = append(validationErrors[errorPrefix], out)
						}
					}
				}

				// buildCOnfig should have the annotation template.alpha.openshift.io/wait-for-ready: "true"
			case *buildapiv1.BuildConfig:
				t.Namespace = "default"
				errorPrefix := fmt.Sprintf("BuildConfig-%s", t.Name)

				// if RunPolicy is empty, set it to Serial
				if t.Spec.RunPolicy == "" {
					t.Spec.RunPolicy = buildapiv1.BuildRunPolicySerial
				}

				buildBuildConfig := &buildapi.BuildConfig{}
				buildconversion.Convert_v1_BuildConfig_To_build_BuildConfig(t, buildBuildConfig, nil)

				if err := buildvalidation.ValidateBuildConfig(buildBuildConfig); err != nil {
					for _, e := range err {
						validationErrors[errorPrefix] = append(validationErrors[errorPrefix], e.Error())
					}
				}

				if t.ObjectMeta.Labels["application"] == "" {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "metadata.labels.[application] cannot be empty.")
				}

				if t.Annotations["template.alpha.openshift.io/wait-for-ready"] != "true" {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "metadata.annotations.[template.alpha.openshift.io/wait-for-ready} cannot be empty or does not contain the expected value: Provided["+t.Annotations["template.alpha.openshift.io/wait-for-ready"]+"]-Expected[true]")
				}

			case *imageapiv1.ImageStream:
				t.Namespace = "default"
				errorPrefix := fmt.Sprintf("ImageStream-%s", t.Name)

				versioned, err := legacyscheme.Scheme.ConvertToVersion(t, imageapi.SchemeGroupVersion)
				if err != nil {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], err.Error())
				}

				imageImageStream := versioned.(*imageapi.ImageStream)
				if err := imagevalidation.ValidateImageStream(imageImageStream); err != nil {
					for _, e := range err {
						validationErrors[errorPrefix] = append(validationErrors[errorPrefix], e.Error())
					}
				}

				if t.ObjectMeta.Labels["application"] == "" {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "metadata.labels.[application] cannot be empty.")
				}

				// deploymentConfig should have the annotation template.alpha.openshift.io/wait-for-ready: "true"
			case *appsapiv1.DeploymentConfig:
				t.Namespace = "default"
				errorPrefix := fmt.Sprintf("DeploymentConfig-%s", t.Name)

				if t.Spec.Template.Spec.RestartPolicy == "" {
					t.Spec.Template.Spec.RestartPolicy = corev1.RestartPolicyAlways
				}

				if t.Spec.Template.Spec.DNSPolicy == "" {
					t.Spec.Template.Spec.DNSPolicy = corev1.DNSDefault
				}

				for i, container := range t.Spec.Template.Spec.Containers {
					if utils.Debug && container.Ports[i].ContainerPort == 0 {
						fmt.Printf("A possible error happened on object kind '%s' and name '%s' while parsing container ports %v\n", reflect.TypeOf(t), t.Name, container.Ports)
					}

					if container.LivenessProbe != nil {
						if container.LivenessProbe.SuccessThreshold == 0 {
							t.Spec.Template.Spec.Containers[i].LivenessProbe.SuccessThreshold = 1
						}
					}

					if container.TerminationMessagePolicy == "" {
						t.Spec.Template.Spec.Containers[i].TerminationMessagePolicy = corev1.TerminationMessageFallbackToLogsOnError
					}

					for j, env := range container.Env {
						if env.ValueFrom != nil {
							t.Spec.Template.Spec.Containers[i].Env[j].ValueFrom.FieldRef.APIVersion = appsapiv1.SchemeGroupVersion.Version
						}
					}

					// check if there is duplicate envs
					seen := make(map[string]struct{}, len(container.Env))
					for _, v := range container.Env {
						if _, ok := seen[v.Name]; ok {
							validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "The following parameter is duplicate: " + v.Name)
							continue
						}
						seen[v.Name] = struct{}{}
					}
				}

				versioned, err := legacyscheme.Scheme.ConvertToVersion(t, appsapi.SchemeGroupVersion)
				if err != nil {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], err.Error())
					if utils.Debug {
						fmt.Printf("Error on convertion Unstructured object to appsapi.DeploymentConfit %v", err.Error())
					}
				}

				appsDeploymentConfig := versioned.(*appsapi.DeploymentConfig)
				if errs := appsvalidation.ValidateDeploymentConfig(appsDeploymentConfig); errs != nil {
					for _, e := range errs {
						validationErrors[errorPrefix] = append(validationErrors[errorPrefix], e.Error())
					}
					if utils.Debug && len(errs) > 0 {
						fmt.Printf("Error on validating DeploymentConfig Object %v", err)
					}
				}

				if t.Labels["application"] == "" {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "metadata.labels.[application] cannot be empty.")
				}

				if t.Labels["service"] == "" {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "metadata.labels.[service] cannot be empty.")
				}

				if t.Annotations["template.alpha.openshift.io/wait-for-ready"] != "true" {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "metadata.annotations.[template.alpha.openshift.io/wait-for-ready] cannot be empty or does not contain the expected value: Provided["+t.Annotations["template.alpha.openshift.io/wait-for-ready"]+"]-Expected[true]")
				}

				if t.Spec.Replicas < 1 {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "spec.replicas should be greater than 0")
				}

				invalidSelector, _ := regexp.MatchString(`\${\w+}*`, t.Spec.Selector["deploymentConfig"])
				if invalidSelector {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "spec.selector[deploymentConfig] should should not be empty or value is not correct. Provided value: "+t.Spec.Selector["deploymentConfig"])
				}

			case *kappsv1.StatefulSet:
				t.Namespace = "default"
				errorPrefix := fmt.Sprintf("StatefulSet-%s", t.Name)

				if t.Spec.Template.Spec.RestartPolicy == "" {
					t.Spec.Template.Spec.RestartPolicy = corev1.RestartPolicyAlways
				}

				if t.Spec.Template.Spec.DNSPolicy == "" {
					t.Spec.Template.Spec.DNSPolicy = corev1.DNSDefault
				}

				for i, container := range t.Spec.Template.Spec.Containers {
					if utils.Debug && container.Ports[i].ContainerPort == 0 {
						fmt.Printf("A possible error happened on object kind '%s' and name '%s' while parsing container ports %v\n", reflect.TypeOf(t), t.Name, container.Ports)
					}

					if container.LivenessProbe != nil {
						if container.LivenessProbe.SuccessThreshold == 0 {
							t.Spec.Template.Spec.Containers[i].LivenessProbe.SuccessThreshold = 1
						}
					}

					if container.TerminationMessagePolicy == "" {
						t.Spec.Template.Spec.Containers[i].TerminationMessagePolicy = corev1.TerminationMessageFallbackToLogsOnError
					}

					for j, env := range container.Env {
						if env.ValueFrom != nil {
							t.Spec.Template.Spec.Containers[i].Env[j].ValueFrom.FieldRef.APIVersion = appsapiv1.SchemeGroupVersion.Version
						}
					}

					// check if there is duplicate envs
					seen := make(map[string]struct{}, len(container.Env))
					for _, v := range container.Env {
						if _, ok := seen[v.Name]; ok {
							validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "The following parameter is duplicate: " + v.Name)
							continue
						}
						seen[v.Name] = struct{}{}
					}
				}

				versioned, err := legacyscheme.Scheme.ConvertToVersion(t, appsapi.SchemeGroupVersion)
				if err != nil {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], err.Error())
					if utils.Debug {
						fmt.Printf("Error on convertion Unstructured object to appsapi.DeploymentConfit %v", err.Error())
					}
				}

				appsDeploymentConfig := versioned.(*appsapi.DeploymentConfig)
				if errs := appsvalidation.ValidateDeploymentConfig(appsDeploymentConfig); errs != nil {
					for _, e := range errs {
						validationErrors[errorPrefix] = append(validationErrors[errorPrefix], e.Error())
					}
					if utils.Debug && len(errs) > 0 {
						fmt.Printf("Error on validating DeploymentConfig Object %v", err)
					}
				}

				if t.Labels["application"] == "" {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "metadata.labels.[application] cannot be empty.")
				}

				if t.Labels["service"] == "" {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "metadata.labels.[service] cannot be empty.")
				}

				if t.Annotations["template.alpha.openshift.io/wait-for-ready"] != "true" {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "metadata.annotations.[template.alpha.openshift.io/wait-for-ready] cannot be empty or does not contain the expected value: Provided["+t.Annotations["template.alpha.openshift.io/wait-for-ready"]+"]-Expected[true]")
				}

			case *krbac.Role:
				t.Namespace = "default"

				if err := krbacvalidation.ValidateRole(t); len(err) > 0 {
					for _, e := range err {
						validationErrors["Role"] = append(validationErrors["Role"], e.Error())
					}
				}

				if t.Labels["application"] == "" {
					validationErrors["Role"] = append(validationErrors["Role"], "metadata.labels.[application] cannot be empty.")
				}

			case *krbac.RoleBinding:
				t.Namespace = "default"

				if err := krbacvalidation.ValidateRoleBinding(t); len(err) > 0 {
					for _, e := range err {
						validationErrors["RoleBinding"] = append(validationErrors["RoleBinding"], e.Error())
					}
				}

				if t.Labels["application"] == "" {
					validationErrors["RoleBinding"] = append(validationErrors["RoleBinding"], "metadata.labels.[application] cannot be empty.")
				}

			default:
				validationErrors["UnrecognizedObjects"] = append(validationErrors["UnrecognizedObjects"], reflect.TypeOf(t).String())
			}
		}
	}
}
