CLUSTER_NAME := vault-agent-secret-injection
NB_NODES := 1

REGISTRY_NAME := vault-agent-secret-injection.localhost
REGISTRY_PORT := 5000


start:
	@bash cluster-init.sh $(CLUSTER_NAME) $(REGISTRY_NAME) $(REGISTRY_PORT) $(NB_NODES)

image:
	@docker build api -t k3d-vault-agent-secret-injection.localhost:5000/api
	@docker push k3d-vault-agent-secret-injection.localhost:5000/api

forward:
	@kubectl port-forward -n vault pod/vault-0 8200:8200 &
	@kubectl port-forward -n api deployment/api-deployment 8080:8080 &

vault:
	@bash vault.sh

api:
	@helm upgrade --install api -n api ./charts/api -f ./charts/api/values.yaml

delete:
	@k3d cluster delete $(CLUSTER_NAME)

cleanup: delete
	@k3d registry delete $(REGISTRY_NAME)

stop:
	@k3d cluster stop $(CLUSTER_NAME) --all
	@docker stop k3d-$(REGISTRY_NAME)

.PHONY: start registry forward vault api delete cleanup stop
