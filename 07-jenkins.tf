resource "helm_release" "jenkins" {
  depends_on       = [module.eks]
  count            = var.enable_jenkins ? 1 : 0
  name             = var.jenkins_name
  namespace        = try(kubernetes_namespace_v1.jenkins[0].metadata[0].name, local.jenkins_namespace)
  create_namespace = false
  chart            = var.jenkins_name
  version          = var.jenkins_chart_version
  repository       = "https://charts.jenkins.io"
  values           = ["${file("${path.module}/helm-values/jenkins-values.yaml")}"]
  set {
    name  = "controller.admin.password"
    value = data.aws_secretsmanager_secret_version.jenkins_admin_password_version.secret_string
  }
  set {
    name  = "persistence.existingClaim"
    value = local.jenkins_ebs_pvc
  }

}

resource "kubernetes_namespace_v1" "jenkins" {
  count = var.enable_jenkins ? 1 : 0
  metadata {
    name = local.jenkins_namespace
  }
  timeouts {
    delete = "15m"
  }
}


resource "kubectl_manifest" "jenkins_ebs_sc" {
  count     = var.enable_jenkins ? 1 : 0
  yaml_body = <<-YAML
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ${local.jenkins_ebs_storage_class}
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  fsType: ext4  
YAML
}

resource "kubectl_manifest" "jenkins_ebs_pvc" {
  count     = var.enable_jenkins ? 1 : 0
  yaml_body = <<-YAML
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${local.jenkins_ebs_pvc}
  namespace: ${kubernetes_namespace_v1.jenkins[0].metadata[0].name} 
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ${local.jenkins_ebs_storage_class}
  resources:
    requests:
      storage: 50Gi
YAML

  depends_on = [kubectl_manifest.jenkins_ebs_sc]
}


resource "kubectl_manifest" "jenkins_secret" {
  count = var.enable_jenkins ? 1 : 0
  sensitive_fields = [
    "data.jenkins-admin-password"
  ]

  yaml_body = <<-YAML
apiVersion: v1
kind: Secret
metadata:
   name: "jenkins"
   namespace: ${kubernetes_namespace_v1.jenkins[0].metadata[0].name}
   labels:
    app.kubernetes.io/managed-by: "Helm"
   annotations:
    meta.helm.sh/release-name: "jenkins"
    meta.helm.sh/release-namespace: "jenkins"
type: Opaque
data:
  jenkins-admin-password: ${base64encode(aws_secretsmanager_secret_version.jenkins.secret_string)}
  jenkins-admin-user: ${base64encode("admin")}
YAML
}

