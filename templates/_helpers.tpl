{{- define "pikadns.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pikadns.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "pikadns.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "pikadns.labels" -}}
app.kubernetes.io/name: {{ include "pikadns.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "pikadns.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pikadns.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* Name of the Secret holding the Cloudflare token, and the key within it. */}}
{{- define "pikadns.secretName" -}}
{{- if .Values.cloudflare.existingSecret -}}
{{- .Values.cloudflare.existingSecret -}}
{{- else -}}
{{- include "pikadns.fullname" . -}}
{{- end -}}
{{- end -}}

{{- define "pikadns.secretKey" -}}
{{- if .Values.cloudflare.existingSecret -}}
{{- .Values.cloudflare.existingSecretKey -}}
{{- else -}}
cf-api-token
{{- end -}}
{{- end -}}
