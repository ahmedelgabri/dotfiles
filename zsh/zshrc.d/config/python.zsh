##############################################################
# Python
###############################################################
export PYTHONSTARTUP=$HOME/.pyrc.py

# disables prompt mangling in virtual_env/bin/activate
export VIRTUAL_ENV_DISABLE_PROMPT=1

# Virtualenvwrapper
export WORKON_HOME=$HOME/.venv
export VIRTUALENVWRAPPER_VIRTUALENV_ARGS='--no-site-packages'
export PIP_VIRTUALENV_BASE=$WORKON_HOME
export PIP_RESPECT_VIRTUALENV=true

# Very slow & I don't use it anymore.
# [ -s "`brew --prefix`/bin/virtualenvwrapper.sh" ] && source "`brew --prefix`/bin/virtualenvwrapper.sh"
