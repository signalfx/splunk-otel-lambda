# Copyright Splunk Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from os import environ
import logging

logger = logging.getLogger(__file__)


def splunk_lambda_sls_zip_handler():
    if environ.get("SPLUNK_LAMBDA_SLS_ZIP", "false") == 'true':
        try:
            logger.info("Trying to import dependencies")
            import unzip_requirements
            import pkg_resources
            pkg_resources.working_set.add_entry("/tmp/sls-py-req")
            logger.info("unzip_requirements imported")
        except ImportError:
            logger.exception("Could not import unzip_requirements")
    else:
        logger.debug("Splunk lambda SLS zip handler disabled")
