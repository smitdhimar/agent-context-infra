# State strategy:
#   - dev      : local state (no remote backend)
#   - staging  : remote backend -> s3://agent-context-tfstate-staging
#   - prod     : remote backend -> s3://agent-context-tfstate-prod
# Create the state buckets once (per region):
#   aws s3api create-bucket --bucket agent-context-tfstate-staging --region us-east-1
#   aws s3api create-bucket --bucket agent-context-tfstate-prod --region us-east-1
# (or point the backend block in environments/<env>/main.tf at existing buckets)
agent-context-%-init:
	cd environments/$* && terraform init
agent-context-%-plan:
	cd environments/$* && terraform plan
agent-context-%-apply:
	cd environments/$* && terraform apply --auto-approve
agent-context-%-destroy:
	cd environments/$* && terraform destroy
