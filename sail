#!/usr/bin/env bash

find_project() {
    current=.
    until [ $current -ef / ]; do
        if [ -f "$current/vendor/bin/sail" ]; then
            echo "$current"
            return 0
        fi
        current+=/..
    done

    return 1
}

sail_run() {
    pushd "$dir" >/dev/null
    ./vendor/bin/sail "$@"
    exit_code=$?
    popd >/dev/null
    return $exit_code
}

sail_run_root() {
    pushd "$dir" >/dev/null
    docker-compose exec -u root "${APP_SERVICE:-laravel.test}" bash -c "$*"
    exit_code=$?
    popd >/dev/null
    return $exit_code
}

should_proxy() {
    PROXY_COMMANDS=(php bin composer artisan debug test phpunit dusk dusk:fails tinker node npm npx yarn mysql mariadb psql shell bash root-shell redis share build convert cp create down events exec images kill logs ls pause port ps pull push restart rm run start stop top unpause up version)
    for proxy in "${PROXY_COMMANDS[@]}"; do
        if [ "$proxy" == "$1" ]; then
            return 0
        fi
    done
    return 1
}

dir="$(find_project)"
[ $? -ne 0 ] && echo "Sail not found" && exit 1
source "$dir/.env"

# Proxy all sail and docker-compose commands
if should_proxy "$1"; then
    sail_run "$@"
else
    # Use the first argument to determine what to do
    case "${1:-}" in
    *:* | migrate | tinker | list)
        sail_run artisan "$@"
        ;;
    i | install)
        shift
        sail_run composer install "$@" && sail_run npm ci
        ;;
    require)
        shift
        sail_run composer require "$@"
        ;;
    dump-autoload)
        shift
        sail_run composer dump-autoload "$@"
        ;;
    dev | watch | hot | production)
        sail_run npm run "$@"
        ;;
    tail)
        sail_run bash -c "tail -f ${2:-storage/logs/*.log}"
        ;;
    root)
        shift
        sail_run_root "$*"
        ;;
    xdebug)
        xdebug_ini=/etc/php/8.0/cli/conf.d/20-xdebug.ini
        case "${2:-status}" in
        on | y | yes | 1)
            sail_run_root "sed -i 's/^#zend_extension/zend_extension/g' $xdebug_ini && export XDEBUG_MODE=develop,debug && pkill -f php" &&
                echo "Xdebug loaded" || echo "Error"
            ;;
        off | n | no | 0)
            sail_run_root "sed -i 's/^zend_extension/#zend_extension/g' $xdebug_ini && export XDEBUG_MODE=off && pkill -f php" &&
                echo "Xdebug unloaded" || echo "Error"
            ;;
        status)
            sail_run_root grep -q '^zend' $xdebug_ini && echo "Xdebug is loaded. Mode: $(sail_run_root echo \$XDEBUG_MODE)" || echo "Xdebug is not loaded"
            ;;
        info)
            sail_run bash -c 'php --ri xdebug'
            ;;
        *)
            echo "Unknown xdebug command: $2"
            ;;
        esac

        ;;
    *)
        # Execute all other commands as bash commands in container
        sail_run bash -c "$*"
        ;;
    esac
fi
