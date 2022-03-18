package com.github.rotty3000.osgi.config.aff;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Deactivate;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.log.Logger;
import org.osgi.service.log.LoggerFactory;

import com.google.common.reflect.TypeToken;

import io.kubernetes.client.openapi.ApiClient;
import io.kubernetes.client.openapi.Configuration;
import io.kubernetes.client.openapi.apis.CoreV1Api;
import io.kubernetes.client.openapi.models.V1ConfigMap;
import io.kubernetes.client.util.Config;
import io.kubernetes.client.util.Watch;
import okhttp3.OkHttpClient;

@Component
public class ConfigMapWatcherComponent {

	private final Logger logger;
	private final Watch<V1ConfigMap> watch;

	@Activate
	@SuppressWarnings("serial")
	public ConfigMapWatcherComponent(@Reference(service=LoggerFactory.class) Logger logger) {
		this.logger = logger;

		try {
			ApiClient client = Config.defaultClient();

			// infinite timeout
			OkHttpClient httpClient = client.getHttpClient().newBuilder().readTimeout(0, TimeUnit.SECONDS).build();

			client.setHttpClient(httpClient);

			Configuration.setDefaultApiClient(client);

			CoreV1Api api = new CoreV1Api();

			watch = Watch.createWatch(
				client,
				api.listConfigMapForAllNamespacesAsync(null, null, null, null, null, null, null, null, null, null),
				new TypeToken<Watch.Response<V1ConfigMap>>() {}.getType()
			);

			for (Watch.Response<V1ConfigMap> item : watch) {
				System.out.printf("%s : %s%n", item.type, item.object.getMetadata().getName());
			}
		}
		catch (Exception e) {
			logger.error(l -> l.error(
				"An error occured when deactivating the watcher: {}", e.getMessage(), e)
			);
		}
	}

	@Deactivate
	public void deactivate() {
		try {
			watch.close();
		}
		catch (IOException ioException) {
			logger.error(l -> l.error(
				"An error occured when deactivating the watcher: {}", ioException.getMessage(), ioException)
			);
		}
	}

}
