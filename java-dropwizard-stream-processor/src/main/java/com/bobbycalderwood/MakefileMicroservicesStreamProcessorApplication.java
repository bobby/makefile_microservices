package com.bobbycalderwood;

import io.dropwizard.Application;
import io.dropwizard.setup.Bootstrap;
import io.dropwizard.setup.Environment;

public class MakefileMicroservicesStreamProcessorApplication extends Application<MakefileMicroservicesStreamProcessorConfiguration> {

    public static void main(final String[] args) throws Exception {
        new MakefileMicroservicesStreamProcessorApplication().run(args);
    }

    @Override
    public String getName() {
        return "MakefileMicroservicesStreamProcessor";
    }

    @Override
    public void initialize(final Bootstrap<MakefileMicroservicesStreamProcessorConfiguration> bootstrap) {
        // TODO: application initialization
    }

    @Override
    public void run(final MakefileMicroservicesStreamProcessorConfiguration configuration,
                    final Environment environment) {
        // TODO: implement application
    }

}
