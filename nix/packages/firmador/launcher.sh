#!@shell@
java_args=()
case "${1-}" in
  firmador:*)
    java_args+=("-Djnlp.remoteOrigin=${1#firmador:}")
    shift
    ;;
esac
exec @java@ "${java_args[@]}" -jar @jar@ "$@"
