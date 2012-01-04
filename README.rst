Erakoon
=======
Erakoon_ is a proof-of-concept Erlang_ client for the Arakoon_ distributed
key-value store.

Currently, it does not support the latest Arakoon protocol format, and as such
can't be used with recent servers. Some work would be required to update the
code accordingly.

.. _Erakoon: http://github.com/Incubaid/erakoon
.. _Erlang: http://www.erlang.org
.. _Arakoon: http://arakoon.org

Building and Testing
--------------------
Erakoon uses the build system included in Erlang/OTP releases and contains an
``Emakefile`` accordingly. There's a utility ``Makefile`` to execute the
necessary actions, use ``make`` to build or ``make test`` to run the
test-suite.

The tests are executed using the ``prove`` utility found in the Perl
*Test-Harness* package, which is a dependency, as well as the Erlang ``etap``
package.
