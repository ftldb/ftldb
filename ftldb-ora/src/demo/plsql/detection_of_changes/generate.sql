--
-- Copyright 2014-2016 Victor Osolovskiy, Sergey Navrotskiy
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

begin

  dbms_java.set_output(1000000); -- to see details of ftl errors

  -- regeneration of code and tables
  demo_dtoch_gen.regenerate(
    demo_dtoch_gen_pr_nt(
      demo_dtoch_gen_pr_ot(
        'demo_whs_goods_src', 'demo_whs_goods_snap',
        'demo_whs_goods_snap_errs', 'demo_whs_goods_diff'
      ),
      demo_dtoch_gen_pr_ot(
        'demo_other1_src', 'demo_other1_snap',
        'demo_other1_snap_errs', 'demo_other1_diff'
      ),
      demo_dtoch_gen_pr_ot(
        'demo_other2_src', 'demo_other2_snap',
        'demo_other2_snap_errs', 'demo_other2_diff'
      )
      /*
      , -- it is possible to add another source view
      demo_dtoch_gen_pr_ot(
        'demo_whs_goods_src', 'demo_whs_goods_snap',
        'demo_whs_goods_snap_errs', 'demo_whs_goods_diff'
      )
      */
    )
  )
  .exec(true);
  --.show();

end;
/
