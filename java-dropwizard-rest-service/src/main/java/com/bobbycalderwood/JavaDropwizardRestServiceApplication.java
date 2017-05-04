package com.bobbycalderwood;

import io.dropwizard.Application;
import io.dropwizard.setup.Bootstrap;
import io.dropwizard.setup.Environment;

public class JavaDropwizardRestServiceApplication extends Application<JavaDropwizardRestServiceConfiguration> {

    public static void main(final String[] args) throws Exception {
        new JavaDropwizardRestServiceApplication().run(args);
    }

    @Override
    public String getName() {
        return "JavaDropwizardRestService";
    }

    @Override
    public void initialize(final Bootstrap<JavaDropwizardRestServiceConfiguration> bootstrap) {
        // TODO: application initialization
    }

    @Override
    public void run(final JavaDropwizardRestServiceConfiguration configuration,
                    final Environment environment) {
        // TODO: implement application
    }

}
