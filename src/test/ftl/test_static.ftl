<#--

    Copyright 2014-2015 Victor Osolovskiy, Sergey Navrotskiy

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

-->
-- ${template_name()} START --
java.lang.System.currentTimeMillis() = ${static("java.lang.System").currentTimeMillis()?c}
java.lang.Math.sqrt(123) = ${static("java.lang.Math").sqrt(123)?c}
java.lang.Math.pow(3, 5) = ${static("java.lang.Math").pow(3, 5)?c}
java.math.RoundingMode.UP = ${static("java.math.RoundingMode").UP}
-- ${template_name()} END --
