package com.devops.springapp.controller;

import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/products")
public class ProductController {

    private final List<Map<String, Object>> products = new ArrayList<>(List.of(
        Map.of("id", 1, "name", "Laptop", "price", 999.99),
        Map.of("id", 2, "name", "Phone", "price", 499.99),
        Map.of("id", 3, "name", "Tablet", "price", 299.99)
    ));

    @GetMapping
    public List<Map<String, Object>> getAllProducts() {
        return products;
    }

    @GetMapping("/{id}")
    public Map<String, Object> getProduct(@PathVariable int id) {
        return products.stream()
            .filter(p -> p.get("id").equals(id))
            .findFirst()
            .orElseThrow(() -> new RuntimeException("Product not found"));
    }

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "UP", "service", "product-service");
    }
}
