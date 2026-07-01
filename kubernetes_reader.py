import requests
from eks_discovery import ClusterContext


def api_request(endpoint: str, path: str, token: str, cluster_name: str, ca_file: str, method: str = "GET"):
    """Faz um request à Kubernetes API com autenticação AWS EKS
    
    Args:
        endpoint: URL base do API server (ex: https://api.example.com)
        path: Caminho do recurso Kubernetes (ex: /api/v1/nodes, /api/v1/pods, /api/v1/namespaces/{ns}/pods)
        token: Token de autenticação AWS EKS
        cluster_name: Nome do cluster (para header x-k8s-aws-id)
        ca_file: Caminho do ficheiro com CA certificate
        method: Método HTTP (GET, POST, etc)
    """
    headers = {
        "Authorization": f"Bearer {token}",
        "x-k8s-aws-id": cluster_name,
        "Content-Type": "application/json"
    }
    
    url = f"{endpoint}{path}"
    response = requests.request(method, url, headers=headers, verify=ca_file)
    
    if response.status_code == 401:
        raise Exception(f"Unauthorized (401): {response.text}")
    elif response.status_code == 403:
        raise Exception(f"Authenticated but without access entries permissions: {response.text}")
    elif response.status_code >= 400:
        raise Exception(f"HTTP {response.status_code}: {response.text}")
    
    return response.json()

def parse_namespaces(data: dict):
    """Converte resposta JSON de namespaces para objetos simples"""
    namespaces = []
    for item in data.get('items', []):
        namespace = type('Namespace', (), {
            'metadata': type('Metadata', (), {'name': item['metadata']['name']})(),
        })()
        namespaces.append(namespace)
    
    return type('NamespaceList', (), {'items': namespaces})()

def parse_nodes(data: dict):
    """Converte resposta JSON de nodes para objetos simples"""
    nodes = []
    for item in data.get('items', []):
        node = type('Node', (), {
            'metadata': type('Metadata', (), {'name': item['metadata']['name']})(),
            'status': type('Status', (), {
                'conditions': [
                    type('Condition', (), {'type': c['type'], 'status': c['status']})()
                    for c in item.get('status', {}).get('conditions', [])
                ]
            })()
        })()
        nodes.append(node)
    
    return type('NodeList', (), {'items': nodes})()

def parse_deployments(data: dict):
    """Converte resposta JSON de deployments para objetos simples"""
    deployments = []
    for item in data.get('items', []):
        deployment = type('Deployment', (), {
            'metadata': type('Metadata', (), {
                'name': item['metadata']['name'],
                'namespace': item['metadata'].get('namespace', 'default')
            })(),
            'status': type('Status', (), {
                'conditions': [
                    type('Condition', (), {'type': c['type'], 'status': c['status'], 'reason': c.get('reason', "")})()
                    for c in item.get('status', {}).get('conditions', [])
                ]
            })()
        })()
        deployments.append(deployment)
    
    return type('DeploymentList', (), {'items': deployments})()

def parse_deployment(deployment):
    """Converte resposta JSON de deployments para objetos simples"""
    newDeployment = type('Deployment', (), {
            'metadata': type('Metadata', (), {
                'name': deployment['metadata']['name'],
                'namespace': deployment['metadata'].get('namespace', 'default')
            })(),
            'status': type('Status', (), {
                'conditions': [
                    type('Condition', (), {'type': c['type'], 'status': c['status'], 'reason': c.get('reason', "")})()
                    for c in deployment.get('status', {}).get('conditions', [])
                ]
            })()
        })()
    
    return newDeployment

def parse_pods(data: dict):
    """Converte resposta JSON de pods para objetos simples"""
    pods = []
    for item in data.get('items', []):
        pod = type('Pod', (), {
            'metadata': type('Metadata', (), {
                'name': item['metadata']['name'],
                'namespace': item['metadata'].get('namespace', 'default')
            })(),
            'status': type('Status', (), {
                'phase': item.get('status', {}).get('phase', 'Unknown')
            })()
        })()
        pods.append(pod)
    
    return type('PodList', (), {'items': pods})()

def parse_argocd_application(data: dict):
    """Converte resposta JSON de uma ArgoCD Application para objeto simples"""
    operation_state = data.get('status', {}).get('operationState', {}) or {}
    health = data.get('status', {}).get('health', {}) or {}
    sync = data.get('status', {}).get('sync', {}) or {}

    return type('ArgoCDApplication', (), {
        'metadata': type('Metadata', (), {
            'name': data['metadata']['name'],
            'namespace': data['metadata'].get('namespace', 'argocd')
        })(),
        'status': type('Status', (), {
            'sync_status': sync.get('status', 'Unknown'),
            'health_status': health.get('status', 'Unknown'),
            'operation_phase': operation_state.get('phase', '')
        })()
    })()

def list_items(cluster: ClusterContext, path, function):
    data = api_request(
        endpoint=cluster.endpoint,
        path=path,
        token=cluster.bearer_token,
        cluster_name=cluster.name,
        ca_file=cluster.ca_file_path
    )
    return function(data)

def list_namespaces(cluster: ClusterContext):
    """Lista todos os namespaces do cluster
    
    Faz request a: GET /api/v1/namespaces
    """
    return list_items(cluster, "/api/v1/namespaces", parse_namespaces)

def list_nodes(cluster: ClusterContext):
    """Lista todos os nodes do cluster
    
    Faz request a: GET /api/v1/nodes
    """
    return list_items(cluster, "/api/v1/nodes", parse_nodes)


def list_pods_all_namespaces(cluster: ClusterContext):
    """Lista todos os pods em todos os namespaces
    
    Faz request a: GET /api/v1/pods
    """
    return list_items(cluster, "/api/v1/pods", parse_pods)


def list_pods_in_namespace(cluster: ClusterContext, namespace: str):
    """Lista todos os pods num namespace específico
    
    Faz request a: GET /api/v1/namespaces/{namespace}/pods
    """
    return list_items(cluster, f"/api/v1/namespaces/{namespace}/pods", parse_pods)

def list_deployment(cluster: ClusterContext, namespace: str, deployment: str):
    """Lista um deployment especifico num namespace específico
    
    Faz request a: GET /apis/apps/v1/namespaces/{namespace}/deployments/{deployment}
    """
    return list_items(cluster, f"/apis/apps/v1/namespaces/{namespace}/deployments/{deployment}", parse_deployment)

def list_deployments(cluster: ClusterContext, namespace: str):
    """Lista todos os deployments num namespace específico
    
    Faz request a: GET /apis/apps/v1/namespaces/{namespace}/deployments
    """
    return list_items(cluster, f"/apis/apps/v1/namespaces/{namespace}/deployments", parse_deployments)

def get_argocd_application(cluster: ClusterContext, app_name: str):
    """Lê uma ArgoCD Application específica

    Faz request a: GET /apis/argoproj.io/v1alpha1/namespaces/argocd/applications/{app_name}
    """
    return list_items(cluster, f"/apis/argoproj.io/v1alpha1/namespaces/argocd/applications/{app_name}", parse_argocd_application)