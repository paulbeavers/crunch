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

## Container-to-container communication
Containers on the same Docker network reach each other directly by service or container name
(e.g. `http://app1/`) over plain HTTP on the app's internal port. This bypasses the router and TLS,
and works across compose projects that join the external `crunch` network.

- **Everything on `crunch` can reach everything else on it.** Keep databases, caches and other
  internal services off it; give each app a private network:

      services:
        web:
          networks: [crunch, internal]   # web-facing: router can reach it
        db:
          networks: [internal]           # only web can reach it
      networks:
        crunch:   { external: true }
        internal: {}                     # private to this compose project

- **Use unique names on the shared network.** If two projects both have a service named `web`,
  `http://web/` round-robins between them. Give each app an alias:

      networks:
        crunch:
          aliases: [myapp]               # other apps call http://myapp:8080

- **Use internal names, not public hostnames.** Inside a container `localhost` means the container
  itself, so `https://app1.localhost` fails; in production a public hostname works but loops out
  through the router.
