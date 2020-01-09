#include <iostream>
#include <cmath>

/**************************************************************************
 * * Function: CheckRange
 * * Description: Checks if a test value is between a lower and upper bound
 * * Parameters: lowerBound, upperBound, testValue
 * * Pre-Conditions: all parameters are ints 
 * * Post-Conditions: checkRange returns True or False
 * ************************************************************************/
bool checkRange(int lowerBound, int upperBound,int testValue) {
    if(testValue < upperBound && testValue > lowerBound) {
        return true;
    } else {
        return false;
    }
}

bool isCapital(char letter) {
    if(isupper(letter)) {
        return true;
    } else {
        return false;
    }
}

bool isEven(int num) {
    if(num % 2 == 0) {
        return true;
    } else {
        return false;
    }
}

bool isOdd(int num) {
    if(num % 2 != 0) {
        return true;
    } else {
        return false;
    }
}

int equalityTest(int num1,int num2) {
    if(num1 < num2) {
        return -1;
    } else if(num1 == num2) {
        return 0;
    } else if(num1 > num2) {
        return 1;
    }
    return 0;
}

bool isFloatEqual(float num1,float num2,float precision) {
    float num3 = num1 - num2;
    num3 = abs(num3);

    if(num3 > precision) {
        return false;
    } else {
        return true;
    }
}

bool isInt(const std::string& s) {
    std::string::const_iterator it = s.begin();
    while (it != s.end() && std::isdigit(*it)) ++it;
    return !s.empty() && it == s.end();
}

int main() {
    std::cout << checkRange(10,20,15);
    std::cout << isCapital('A');
    std::cout << isEven(4);
    std::cout << isOdd(3);
    std::cout << equalityTest(3,2);
    std::cout << isFloatEqual(2.0,3.5,0.1);
    std::cout << isInt("1");

    return 0;
}