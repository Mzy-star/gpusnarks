/*****************************************************************************
 Implementation of Fast Fourier Transformation on Finite Elements
 *****************************************************************************
 * @author     Marius van der Wijden
 * Copyright [2019] [Marius van der Wijden]
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *****************************************************************************/

#define DEBUG

#include "device_field.h"
#include "device_field_operators.h"
#include <assert.h>

namespace fields{

    void printField(fields::Field f)
    {
        for(size_t i = 0; i < SIZE; i++)
            printf("%u, ", f.im_rep[i]);
        printf("\n");
    }

    void testEquality(fields::Field f1, fields::Field f2)
    {
        for(size_t i = 0; i < SIZE; i++)
            if(f1.im_rep[i] != f2.im_rep[i])
            {
                printField(f1);
                printField(f2);
                assert(!"Missmatch");
            }
    }

    void testAdd()
    {
        fields::Field f1(1234);
        fields::Field f2(1234);
        fields::Field result(2468);
        add(f1,f2);
        assert(f1 == f2);
    }

    void testSubstract()
    {
        fields::Field f1(1234);
        fields::Field f2(1234);
        substract(f1,f2);
        assert(f1 == fields::Field::zero());
        fields::Field f3(1235);
        substract(f3, f2);
        assert(f3 == fields::Field::one());
    }

    void testModulo()
    {
        fields::Field f1(uint32_t(0));
        fields::Field f2(1234);
        
        fields::Field f3();
    }

    void testMultiply()
    {
        fields::Field f1(1234);
        fields::Field f2(1234);
        mul(f1, f2);
        assert(f1 == fields::Field(1522756));
        fields::Field f3(1234);
        square(f3);
        assert(f1 == f3);
    }

    void testPow()
    {
        fields::Field f1(2);
        pow(f1, 0);
        assert(f1 == fields::Field::one());
        pow(f1, 2);
        assert(f1 == fields::Field(4));
        pow(f1, 10);
        assert(f1 == fields::Field(1048576));

        fields::Field f2(2);
        fields::Field f3(1048576);
        pow(f2, 20);
        assert(f2 == f3);

}
    void testConstructor()
    {
        fields::Field f3(1);
        testEquality(f3, fields::Field::one());
        fields::Field f4;
        testEquality(f4, fields::Field::zero());
        fields::Field f5(uint32_t(0));
        testEquality(f5, fields::Field::zero());

        fields::Field f1;
        fields::Field f2(1234);
        add(f1, fields::Field(1234));
        testEquality(f1, f2);
        uint32_t tmp [SIZE] ={0,0,0,0,0,0,0,1234};
        fields::Field f6(tmp);
        testEquality(f6, f2);
    }
}

int main(int argc, char** argv)
{
    fields::testConstructor();
    return 0;
}



