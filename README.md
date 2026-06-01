# pikadns Helm chart

Deploys [pikadns](https://github.com/ilp0/pikadns) — an on-the-fly wildcard DNS
provisioner backed by the Cloudflare API — to any Kubernetes cluster (k3s, EKS,
GKE, AKS, kubeadm, …). Bring your own ingress controller (Traefik, nginx, …).

## How it works

A wildcard `*.pika.example.com` points at your ingress. The first request for
`app.10.0.0.1.pika.example.com` reaches pikadns, which parses the IP from the
host and creates the matching A record in Cloudflare, then redirects you to it.

## Prerequisites

- A domain on Cloudflare and its **zone ID**.
- A Cloudflare **API token** with `DNS:Edit` on that zone.
- An ingress controller, and a wildcard DNS record `*.<baseDomain>` pointing at
  your ingress / load balancer IP.

## Install

Create the API token secret (recommended over putting the token in values):

```sh
kubectl create namespace pikadns
kubectl -n pikadns create secret generic pikadns-cf \
  --from-literal=cf-api-token=<YOUR_CLOUDFLARE_TOKEN>
```

Install the chart (Traefik shown — see the Ingress vs IngressRoute note below):

```sh
helm install pikadns . -n pikadns \
  --set baseDomain=pika.example.com \
  --set cloudflare.zoneId=<ZONE_ID> \
  --set cloudflare.existingSecret=pikadns-cf \
  --set ingress.enabled=false \
  --set ingressRoute.enabled=true
```

Or with your own values file (keep it out of git — it's your environment):

```sh
helm install pikadns . -n pikadns -f my-values.yaml
```

```yaml
# my-values.yaml
baseDomain: pika.example.com
cloudflare:
  zoneId: "<ZONE_ID>"
  existingSecret: pikadns-cf
# On Traefik, use an IngressRoute — a plain wildcard Ingress only matches one
# label and won't catch app.10.0.0.1.pika.example.com (see note below).
ingress:
  enabled: false
ingressRoute:
  enabled: true
```

> **Ingress vs IngressRoute.** A standard Kubernetes Ingress wildcard
> (`*.pika.example.com`) matches a single label only, so it does **not** match
> the multi-label hosts pikadns relies on (`app.10.0.0.1.pika.example.com`). On
> Traefik, use `ingressRoute` (a `HostRegexp` CRD). On other controllers, point
> a host/regex rule covering all subdomains at the service.

## Configuration

| Key                          | Default                  | Description                                              |
| ---------------------------- | ------------------------ | -------------------------------------------------------- |
| `baseDomain`                 | `""` **(required)**      | Domain pikadns owns, e.g. `pika.example.com`             |
| `recordTtl`                  | `300`                    | TTL of created A records                                 |
| `cloudflare.zoneId`          | `""` **(required)**      | Cloudflare zone ID                                       |
| `cloudflare.apiToken`        | `""`                     | Token inline; chart creates the Secret                   |
| `cloudflare.existingSecret`  | `""`                     | Name of a pre-made Secret holding the token (preferred)  |
| `cloudflare.existingSecretKey` | `cf-api-token`         | Key within `existingSecret`                              |
| `image.repository`           | `ghcr.io/ilp0/pikadns`  | Image                                                    |
| `image.tag`                  | `latest`                 | Image tag                                                |
| `replicaCount`               | `1`                      | Replicas                                                 |
| `service.port`               | `80`                     | Service port                                             |
| `ingress.enabled`            | `true`                   | Create an Ingress                                        |
| `ingress.className`          | `""`                     | Ingress class (`traefik`, `nginx`, … / empty = default)  |
| `ingress.host`               | `""` **(required)**      | Wildcard host, e.g. `*.pika.example.com`                 |
| `ingress.annotations`        | `{}`                     | Ingress annotations                                      |
| `ingress.tls.enabled`        | `false`                  | Enable TLS on the ingress                                |
| `ingress.tls.secretName`     | `""`                     | TLS secret (wildcard cert for `*.<baseDomain>`)          |
| `ingressRoute.enabled`       | `false`                  | Create a Traefik IngressRoute (matches multi-label hosts)|
| `ingressRoute.entryPoints`   | `[web]`                  | Traefik entry points                                     |
| `ingressRoute.match`         | `""`                     | Match rule (defaults to `HostRegexp` of `baseDomain`)    |

### HTTPS

pikadns needs a **wildcard** certificate (`*.<baseDomain>`), which means a
DNS-01 issuer. With cert-manager, create a wildcard `Certificate` and point
`ingress.tls.secretName` at it.

## Verify

```sh
helm test pikadns -n pikadns   # (if tests are enabled)
kubectl -n pikadns get pods
curl -H 'Host: app.10.0.0.1.pika.example.com' http://<ingress-ip>/?json
```

## CI

`.github/workflows/ci.yaml` lints and renders the chart (both the Ingress and
Traefik IngressRoute paths) on every push and PR. It deploys nothing — keep your
own values file local and run `helm upgrade --install -f your-values.yaml`
yourself, or wire your own deploy step with a `KUBECONFIG` secret.

## Uninstall

```sh
helm uninstall pikadns -n pikadns
```

Created A records are **not** removed — delete them in Cloudflare if needed.
