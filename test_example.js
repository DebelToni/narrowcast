// Test JavaScript file for narrow-search plugin

function greetUser(name) {
    console.log(`Hello, ${name}!`);
    return `Welcome, ${name}`;
}

const calculateSum = (a, b) => {
    return a + b;
};

class Calculator {
    constructor() {
        this.result = 0;
    }
    
    add(value) {
        this.result += value;
        return this;
    }
    
    multiply(value) {
        this.result *= value;
        return this;
    }
}

function processData(data) {
    // Process some data
    const processed = data.map(item => item * 2);
    return processed;
}

export function exportedFunction() {
    return "I'm exported!";
}

export class ExportedClass {
    method() {
        return "From exported class";
    }
}
