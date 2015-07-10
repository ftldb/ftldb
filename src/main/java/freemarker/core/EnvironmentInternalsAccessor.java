/*
 * Copyright 2014-2015 Victor Osolovskiy, Sergey Navrotskiy
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package freemarker.core;


/**
 * This class accesses the internals of {@link Environment} that are non-public.
 *
 * @deprecated Should be reviewed on future FreeMarker releases.
 */
public class EnvironmentInternalsAccessor {

    /**
     * Returns the snapshot of the FTL stack trace.
     *
     * @return the FTL instruction stack
     *
     * @see Environment#getInstructionStackSnapshot()
     */
    public static TemplateElement[] getInstructionStackSnapshot() {
        return Environment.getCurrentEnvironment().getInstructionStackSnapshot();
    }

}
