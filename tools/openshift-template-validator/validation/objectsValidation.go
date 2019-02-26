package validation

import (
	"fmt"
	"math/rand"
	"reflect"
	"regexp"
	"strings"
	"time"

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
	kappsv1 "k8s.io/api/apps/v1"
	kappsv1beta1 "k8s.io/api/apps/v1beta1"
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	rbacv1beta1 "k8s.io/api/rbac/v1beta1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/kubernetes/pkg/api/legacyscheme"
	kapi "k8s.io/kubernetes/pkg/apis/core"
	kapiv1 "k8s.io/kubernetes/pkg/apis/core/v1"
	kvalidation "k8s.io/kubernetes/pkg/apis/core/validation"
	krbac "k8s.io/kubernetes/pkg/apis/rbac"
	krbacvalidation "k8s.io/kubernetes/pkg/apis/rbac/validation"

	"github.com/jboss-container-images/jboss-kie-modules/tools/openshift-template-validator/utils"
	k8sapps "k8s.io/kubernetes/pkg/apis/apps"
	//k8sappsv1 "k8s.io/kubernetes/pkg/apis/apps/v1"
	k8svalidation "k8s.io/kubernetes/pkg/apis/apps/validation"
)

func validateObjects(template templateapi.Template) {

	if !utils.DisableDefer {
		defer utils.RecoverFromPanic()
	}

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

				imageStream := versioned.(*imageapi.ImageStream)
				if err := imagevalidation.ValidateImageStream(imageStream); err != nil {
					for _, e := range err {
						validationErrors[errorPrefix] = append(validationErrors[errorPrefix], e.Error())
					}
				}

				if t.ObjectMeta.Labels["application"] == "" {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "metadata.labels.[application] cannot be empty.")
				}

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
					if utils.Debug && len(container.Ports) > 0 && container.Ports[i].ContainerPort == 0 {
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
							validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "The following parameter is duplicate: "+v.Name)
							continue
						}
						seen[v.Name] = struct{}{}
					}
				}

				versioned, err := legacyscheme.Scheme.ConvertToVersion(t, appsapi.SchemeGroupVersion)
				if err != nil {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], err.Error())
					if utils.Debug {
						fmt.Printf("Error on convertion Unstructured object to appsapi.DeploymentConfig %v", err.Error())
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
				errorPrefix := fmt.Sprintf("kappsv1-StatefulSet-%s", t.Name)
				drainerErrorPrefix := fmt.Sprintf("kappsv1-StatefulSet-statefulsets.kubernetes.io/drainer-pod-template-%s", t.Name)

				versioned, err := legacyscheme.Scheme.ConvertToVersion(t, kappsv1.SchemeGroupVersion)
				if err != nil {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], err.Error())
					if utils.Debug {
						fmt.Printf("Error on convertion Unstructured object to kappsv1.StatefulSet %v", err.Error())
					}
				}

				statefulSetv1k8sapps := &k8sapps.StatefulSet{}
				if err := legacyscheme.Scheme.Convert(versioned, statefulSetv1k8sapps, nil); err != nil {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], err.Error())
				}

				// if null, set updateStrategy
				// updateStrategy:
				// rollingUpdate:
				// partition: 0
				// 	type: RollingUpdate
				if statefulSetv1k8sapps.Spec.UpdateStrategy.Type == "" {
					statefulSetv1k8sapps.Spec.UpdateStrategy.Type = "RollingUpdate"
				}

				if err := k8svalidation.ValidateStatefulSet(statefulSetv1k8sapps); err != nil {
					for _, e := range err {
						validationErrors[errorPrefix] = append(validationErrors[errorPrefix], e.Error())
					}
				}

				// validate the drainer Pod if exist
				data := statefulSetv1k8sapps.Annotations["statefulsets.kubernetes.io/drainer-pod-template"]
				if len(data) > 0 {
					drainerPodTemplate := &corev1.Pod{}
					if err := runtime.DecodeInto(legacyscheme.Codecs.UniversalDecoder(), []byte(data), drainerPodTemplate); err != nil {
						validationErrors[drainerErrorPrefix] = append(validationErrors[drainerErrorPrefix], err.Error())
					}

					drainerPodv1 := &kapi.Pod{}
					kapiv1.Convert_v1_Pod_To_core_Pod(drainerPodTemplate, drainerPodv1, nil)

					drainerPodv1.Namespace = "default"

					// if empty, set the restartPolicy to its default value
					if drainerPodv1.Spec.RestartPolicy == "" {
						drainerPodv1.Spec.RestartPolicy = "Always"
					}

					// if empty, set the dnsPolicy to its default value
					if drainerPodv1.Spec.DNSPolicy == "" {
						drainerPodv1.Spec.DNSPolicy = "ClusterFirst"
					}

					for index, container := range drainerPodv1.Spec.Containers {
						// if imagePullPolicy is not present, set to default value
						if container.ImagePullPolicy == "" {
							drainerPodv1.Spec.Containers[index].ImagePullPolicy = "IfNotPresent"
						}

						// set the termination Message Path and MessagePolicy to its default value if empty
						if container.TerminationMessagePolicy == "" {
							drainerPodv1.Spec.Containers[index].TerminationMessagePolicy = "File"
							drainerPodv1.Spec.Containers[index].TerminationMessagePath = "/dev/termination-log"
						}

						// if env contains the value from valueRef, set ApiVersion
						for _, env := range container.Env {
							if env.ValueFrom != nil {
								if env.ValueFrom.FieldRef != nil {
									env.ValueFrom.FieldRef.APIVersion = "v1"
								}
							}
						}
						// ignore volumeMount from drainer pod, sometimes it can use a previously created Volume.
						for i := range container.VolumeMounts {
							if container.VolumeMounts[i].Name != "" {
								drainerPodv1.Spec.Volumes = getFakeVolume(*drainerPodv1)
								container.VolumeMounts[i] = kapi.VolumeMount{
									Name:      "ignore",
									MountPath: "/dev/null",
								}
							}
						}
					}

					if err := kvalidation.ValidatePod(drainerPodv1); err != nil {
						for _, e := range err {
							validationErrors[drainerErrorPrefix] = append(validationErrors[drainerErrorPrefix], e.Error())
						}
					}
				}

			case *kappsv1beta1.StatefulSet:
				warningPrefix := fmt.Sprintf("v1beta1-StatefulSet-%s", t.Name)
				validationWarnings[warningPrefix] = append(validationWarnings[warningPrefix], "Warning, consider move your StatefulSet to v1. No validation will be made.")

			case *rbacv1.Role:
				t.Namespace = "default"
				errorPrefix := fmt.Sprintf("rbacv1-Role-%s", t.Name)

				versioned, err := legacyscheme.Scheme.ConvertToVersion(t, rbacv1.SchemeGroupVersion)
				if err != nil {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], err.Error())
					if utils.Debug {
						fmt.Printf("Error on convertion Unstructured object to rbacv1.Role %v", err.Error())
					}
				}

				krbacRole := &krbac.Role{}
				if err := legacyscheme.Scheme.Convert(versioned, krbacRole, nil); err != nil {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], err.Error())
				}

				if err := krbacvalidation.ValidateRole(krbacRole); err != nil {
					for _, e := range err {
						validationErrors[errorPrefix] = append(validationErrors[errorPrefix], e.Error())
					}
				}

				if krbacRole.ObjectMeta.Labels["application"] == "" {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], "metadata.labels.[application] cannot be empty.")
				}

				for _, rule := range krbacRole.Rules {
					if err := krbacvalidation.ValidatePolicyRule(rule, false, nil); err != nil {
						for _, e := range err {
							validationErrors[errorPrefix] = append(validationErrors[errorPrefix], e.Error())
						}
					}
				}

			case *rbacv1beta1.Role:
				warningPrefix := fmt.Sprintf("rbacv1beta1-Role-%s", t.Name)
				validationWarnings[warningPrefix] = append(validationWarnings[warningPrefix], "Warning, consider move your Role to v1. No validation will be made.")

			case *rbacv1.RoleBinding:
				t.Namespace = "default"
				errorPrefix := fmt.Sprintf("rbacv1-RoleBinding-%s", t.Name)

				versioned, err := legacyscheme.Scheme.ConvertToVersion(t, rbacv1.SchemeGroupVersion)
				if err != nil {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], err.Error())
					if utils.Debug {
						fmt.Printf("Error on convertion Unstructured object to rbacv1.Role %v", err.Error())
					}
				}

				krbacRoleBinding := &krbac.RoleBinding{}
				if err := legacyscheme.Scheme.Convert(versioned, krbacRoleBinding, nil); err != nil {
					validationErrors[errorPrefix] = append(validationErrors[errorPrefix], err.Error())
				}
				if err := krbacvalidation.ValidateRoleBinding(krbacRoleBinding); err != nil {
					for _, e := range err {
						validationErrors[errorPrefix] = append(validationErrors[errorPrefix], e.Error())
					}
				}

				for _, subject := range krbacRoleBinding.Subjects {
					subject.Namespace = "default"
					if err := krbacvalidation.ValidateRoleBindingSubject(subject, false, nil); err != nil {
						for _, e := range err {
							validationErrors[errorPrefix] = append(validationErrors[errorPrefix], e.Error())
						}
					}
				}

			case *rbacv1beta1.RoleBinding:
				warningPrefix := fmt.Sprintf("rbacv1beta1-RoleBinding-%s", t.Name)
				validationWarnings[warningPrefix] = append(validationWarnings[warningPrefix], "Warning, consider move your RoleBinding to v1. No validation will be made.")

			default:
				validationErrors["UnrecognizedObjects"] = append(validationErrors["UnrecognizedObjects"], reflect.TypeOf(t).String())
			}
		}
	}
}

func getFakeVolume(drainerPod kapi.Pod) []kapi.Volume {
	// create a fake VOlume,
	return []kapi.Volume{
		{Name: "ignore", VolumeSource: kapi.VolumeSource{EmptyDir: &kapi.EmptyDirVolumeSource{}}},
	}
}
