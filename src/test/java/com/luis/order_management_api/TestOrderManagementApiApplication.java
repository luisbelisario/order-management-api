package com.luis.order_management_api;

import org.springframework.boot.SpringApplication;

public class TestOrderManagementApiApplication {

	public static void main(String[] args) {
		SpringApplication.from(OrderManagementApiApplication::main).with(TestcontainersConfiguration.class).run(args);
	}

}
