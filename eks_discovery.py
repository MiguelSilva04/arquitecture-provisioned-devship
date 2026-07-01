import base64
import tempfile
from dataclasses import dataclass
from eks_token_generator import generate_eks_bearer_token

@dataclass
class ClusterContext:
    name: str
    arn: str
    region: str
    version: str
    status: str
    endpoint: str
    ca_certificate: str
    bearer_token: str
    ca_file_path: str = ""

def create_ca_file(ca_certificate: str) -> str:
    ca_cert_bytes = base64.b64decode(ca_certificate)
    ca_file = tempfile.NamedTemporaryFile(delete=False, suffix='.crt')
    ca_file.write(ca_cert_bytes)
    ca_file.close()
    return ca_file.name

def extract_region_from_eks_arn(cluster_arn: str) -> str:
    parts = cluster_arn.split(":")

    if len(parts) < 6:
        raise ValueError(f"ARN inválido: {cluster_arn}")

    service = parts[2]
    region = parts[3]

    if service != "eks":
        raise ValueError(f"O ARN não pertence ao serviço EKS: {cluster_arn}")

    return region


def discover_eks_clusters(session, region: str, role_arn: str) -> list[ClusterContext]:
    eks_client = session.client("eks")
    
    response = eks_client.list_clusters()
    cluster_names = response.get("clusters", [])

    clusters: list[ClusterContext] = []

    for cluster_name in cluster_names:
        cluster_data = eks_client.describe_cluster(name=cluster_name)["cluster"]

        cluster_region_from_arn = extract_region_from_eks_arn(cluster_data["arn"])

        if cluster_region_from_arn != region:
            raise RuntimeError(
                f"Região inconsistente no cluster {cluster_name}. "
                f"Região usada no cliente EKS: {region}. "
                f"Região extraída do ARN: {cluster_region_from_arn}."
            )

        bearer_token = generate_eks_bearer_token (
            session=session,
            cluster_name = cluster_data["name"],
            region = cluster_region_from_arn,
        )

        cluster = ClusterContext(
                name=cluster_data["name"],
                arn=cluster_data["arn"],
                region=cluster_region_from_arn,
                version=cluster_data["version"],
                status=cluster_data["status"],
                endpoint=cluster_data["endpoint"],
                ca_certificate=cluster_data["certificateAuthority"]["data"],
                bearer_token=bearer_token,
            )
        cluster.ca_file_path = create_ca_file(cluster.ca_certificate)

        clusters.append(cluster)

    return clusters