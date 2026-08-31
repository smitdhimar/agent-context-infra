# agent-context infra targets a bucket for terraform state. Run once to create it:
#   aws s3api create-bucket --bucket agent-context-tfstate --region us-east-1
# (or point the backend block in environments/<env>/main.tf at an existing bucket)
agent-context-%-init:
	cd environments/$* && terraform init
agent-context-%-plan:
	cd environments/$* && terraform plan
agent-context-%-apply:
	cd environments/$* && terraform apply --auto-approve
agent-context-%-destroy:
	cd environments/$* && terraform destroy
