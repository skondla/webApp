.PHONY: deploy
deploy:
#	@kubectl apply -f secret_pg.yaml -f pv_pg.yaml -f pvc_pg.yaml -f deployment_pg.yaml -f service_pg.yaml
	@kubectl apply -f secret_pg.yaml -f csi_storage_class_pg.yaml -f csi_pvc_pg.yaml -f deployment_pg.yaml -f service_pg.yaml
