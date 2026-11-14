# crunch — container runtime

Runs many containers on one node (macOS or Linux, Docker) behind a single containerized
entry point (`crunch-router`, Traefik v3) that routes by hostname/path, like Apache virtual hosts, and terminates TLS.

## Quick start
    ./scripts/setup.sh        # creates .env (dashboard password) + local TLS cert
    docker compose up -d
    open https://app1.localhost https://app2.localhost https://localhost/api https://traefik.localhost

## Add a site
Attach any container to the `crunch` network and add labels; the router picks it up automatically, no restart needed:

    myapp:
      image: myorg/myapp
      networks: [crunch]
      labels:
        traefik.enable: "true"
        traefik.http.routers.myapp.rule: Host(`myapp.${DOMAIN}`)        # or && PathPrefix(`/x`)
        traefik.http.routers.myapp.entrypoints: websecure
        traefik.http.services.myapp.loadbalancer.server.port: "8080"     # if it exposes >1 port

Containers in other compose projects can join with `networks: { crunch: { external: true } }`.

## TLS
- **Local:** `certs/local.crt` (self-signed; `brew install mkcert` then rerun `scripts/gen-local-cert.sh` for browser-trusted).
- **Production:** set `DOMAIN` and `ACME_EMAIL` in `.env`, point DNS at the node, then
  `docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d` — Let's Encrypt certificates are issued and renewed automatically.
