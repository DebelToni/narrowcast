#!/usr/bin/env python3
"""Test file for the narrow-search plugin."""

def hello_world():
    """Simple function to test narrowing."""
    print("Hello, World!")
    return 42

class TestClass:
    """A test class with methods."""
    
    def __init__(self, name):
        self.name = name
    
    def greet(self):
        """Greet method."""
        print(f"Hello, {self.name}!")
    
    def calculate(self, x, y):
        """Calculate something."""
        result = x + y
        print(f"Result: {result}")
        return result

def another_function(param1, param2):
    """Another function for testing."""
    if param1 > param2:
        return param1
    else:
        return param2

class AnotherClass:
    """Another test class."""
    
    def method_one(self):
        pass
    
    def method_two(self):
        pass
