package com.logistics.gateway.model;

public class SwaggerResource {
    private String name;
    private String location;
    private String swaggerVersion;

    public SwaggerResource() {}

    public SwaggerResource(String name, String location, String swaggerVersion) {
        this.name = name;
        this.location = location;
        this.swaggerVersion = swaggerVersion;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public String getSwaggerVersion() {
        return swaggerVersion;
    }

    public void setSwaggerVersion(String swaggerVersion) {
        this.swaggerVersion = swaggerVersion;
    }
}