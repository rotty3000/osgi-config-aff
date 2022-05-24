package com.github.rotty3000.osgi.config.aff;

import java.util.Dictionary;
import java.util.Hashtable;
import java.util.concurrent.Callable;

import org.osgi.framework.BundleActivator;
import org.osgi.framework.BundleContext;
import org.osgi.framework.ServiceRegistration;

public class StartupMeasurementBundleActivator implements BundleActivator {

	@Override
	public void start(BundleContext context) throws Exception {
		Dictionary<String, Object> props = new Hashtable<>();
		props.put("main.thread", "true");

		reg = context.registerService(
			Callable.class, new MainThread(), props
		);
	}

	@Override
	public void stop(BundleContext context) throws Exception {
		reg.unregister();
	}

	public static class MainThread implements Callable<Integer> {

		@Override
		public Integer call() throws Exception {
			System.out.println("==> I'm done!");
			return Integer.valueOf(0);
		}

	}

	private volatile ServiceRegistration<?> reg;

}
