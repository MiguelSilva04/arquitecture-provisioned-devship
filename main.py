from aws_auth import assume_user_role
from eks_discovery import discover_eks_clusters
from kubernetes_reader import list_nodes, list_pods_all_namespaces, list_pods_in_namespace


USER_ROLE_ARN = "arn:aws:iam::306667525254:role/AccessPlatformDevShip"
DEVSHIP_EXTERNAL_ID = "o-meu-teste-secreto-123"
REGION_AWS = "us-east-1"


def main():
    print("1. A assumir IAM Role via AWS STS...")

    session = assume_user_role(
        role_arn=USER_ROLE_ARN,
        external_id=DEVSHIP_EXTERNAL_ID,
        region=REGION_AWS,
    )

    print("Role assumida com sucesso.\n")

    print("2. A descobrir clusters EKS...")

    clusters = discover_eks_clusters(
        session=session,
        region=REGION_AWS,
        role_arn=USER_ROLE_ARN,
    )

    print(f"Número de clusters encontrados: {len(clusters)}\n")

    for cluster in clusters:
        print(f"Cluster: {cluster.name}")
        print(f"ARN: {cluster.arn}")
        print(f"Região: {cluster.region}")
        print(f"Estado: {cluster.status}")
        print(f"Versão Kubernetes: {cluster.version}")

        print("\n3. A consultar nodes através da Kubernetes API...")


        nodes = list_nodes(cluster)

        for node in nodes.items:
            print(
                f"- {node.metadata.name} | "
                f"status: {get_node_ready_status(node)}"
            )

        print("\n4. A consultar pods através da Kubernetes API...")

        pods = list_pods_all_namespaces(cluster)

        for pod in pods.items:
            print(
                f"- {pod.metadata.namespace}/{pod.metadata.name}"
                f"status - {pod.status.phase}"
            )
        print("A consultar os pods só do namespace criado de testes: ")

        pods = list_pods_in_namespace(cluster, "devship-test-namespace")

        for pod in pods.items:
            print(
                f"- {pod.metadata.name}"
                f"status - {pod.status.phase}"
            )

        print("\n---\n")


def get_node_ready_status(node) -> str:
    for condition in node.status.conditions:
        if condition.type == "Ready":
            return condition.status

    return "Unknown"


if __name__ == "__main__":
    main()