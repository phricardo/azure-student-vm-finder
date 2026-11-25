#!/usr/bin/env bash

python3 -u <<'PY'
import json
import time
import subprocess
import urllib.request
import urllib.parse

def az(*args):
    return json.loads(subprocess.check_output(
        ["az", *args, "--only-show-errors", "-o", "json"],
        text=True, timeout=120
    ))

print("=" * 60)
print("AZURE VM FINDER - DEBIAN LAB")
print("=" * 60)

# 1. Assinatura
account = az("account", "show")
sub = account["id"]

print("\nAssinatura:", account["name"])
print("Status:", account["state"])

if account["state"] != "Enabled":
    raise SystemExit("Assinatura inativa.")

# 2. Registro do provedor
print("\nVerificando Microsoft.Compute...")

start = time.monotonic()
requested = False

while True:
    state = az(
        "provider", "show",
        "--namespace", "Microsoft.Compute"
    )["registrationState"]

    elapsed = int(time.monotonic() - start)
    print(f"Status: {state} | {elapsed}s")

    if state == "Registered":
        break

    if state != "Registering" and not requested:
        az("provider", "register",
           "--namespace", "Microsoft.Compute")
        requested = True

    if elapsed >= 600:
        raise SystemExit("Timeout no registro do provedor.")

    time.sleep(10)

# 3. Regioes permitidas pela politica
print("\nIdentificando regioes permitidas...")

policies = az(
    "policy", "assignment", "list",
    "--filter", "atScope()"
)

allowed = []

for policy in policies:
    params = policy.get("parameters") or {}
    locations = params.get(
        "listOfAllowedLocations", {}
    ).get("value")

    if isinstance(locations, list):
        allowed.append(set(locations))

if not allowed:
    raise SystemExit(
        "Nenhuma politica de regioes reconhecida. "
        "Verifique as permissoes da assinatura."
    )

regions = sorted(set.intersection(*allowed))

if not regions:
    raise SystemExit("Nenhuma regiao permitida encontrada.")

for region in regions:
    print(" -", region)

# 4. Autenticacao da API REST
token = az("account", "get-access-token")["accessToken"]

base = (
    "https://management.azure.com/subscriptions/"
    + sub + "/providers/Microsoft.Compute"
)

def get_pages(url):
    while url:
        req = urllib.request.Request(
            url,
            headers={"Authorization": "Bearer " + token}
        )

        with urllib.request.urlopen(req, timeout=90) as res:
            data = json.load(res)

        yield from data.get("value", [])
        url = data.get("nextLink")

# 5. Consulta de cotas e SKUs
results = []
errors = []

for index, region in enumerate(regions, 1):

    print(f"\n[{index}/{len(regions)}] Consultando {region}...")

    try:
        usage_url = (
            f"{base}/locations/{region}/usages"
            "?api-version=2025-04-01"
        )

        quotas = {
            item["name"]["value"].lower():
            item["limit"] - item["currentValue"]
            for item in get_pages(usage_url)
        }

        regional = quotas.get("cores", 0)

        if regional < 1:
            print("Cota regional insuficiente ou desconhecida.")
            continue

        query = urllib.parse.urlencode({
            "api-version": "2021-07-01",
            "$filter": f"location eq '{region}'"
        })

        found = 0

        for sku in get_pages(f"{base}/skus?{query}"):

            name = sku.get("name", "")

            if sku.get("resourceType") != "virtualMachines":
                continue

            if not name.startswith("Standard_B"):
                continue

            if sku.get("restrictions"):
                continue

            caps = {
                c["name"]: c["value"]
                for c in sku.get("capabilities", [])
            }

            cpu = int(caps.get("vCPUs", 0))
            ram = float(caps.get("MemoryGB", 0))
            arch = caps.get("CpuArchitectureType", "Unknown")
            family = sku.get("family", "").lower()

            if cpu not in (1, 2) or not 1 <= ram <= 8:
                continue

            if arch.lower() not in ("x64", "arm64"):
                continue

            if "V2" not in caps.get("HyperVGenerations", "").split(","):
                continue

            if min(regional, quotas.get(family, 0)) < cpu:
                continue

            results.append((region, name, cpu, ram, arch))
            found += 1

        print(f"Concluido: {found} modelos elegiveis.")

    except Exception as error:
        errors.append(region)
        print(f"Falha na consulta: {error}")

# 6. Ordenacao por preferencia para laboratorio
results.sort(key=lambda vm: (
    vm[4].lower() != "x64",
    abs(vm[3] - 4),
    vm[2],
    vm[0],
    vm[1]
))

print("\n" + "=" * 75)
print("MODELOS ENCONTRADOS")
print("=" * 75)

print(f"{'REGIAO':20} {'MODELO':25} {'CPU':5} {'RAM':8} {'ARQUITETURA'}")

for region, name, cpu, ram, arch in results:
    print(f"{region:20} {name:25} {cpu:<5} {ram:<8g} {arch}")

if errors:
    print("\nRegioes com falha:", ", ".join(errors))

if not results:
    raise SystemExit("\nNenhuma VM elegivel encontrada.")

# 7. Verificacao da imagem Debian
recommended = None
images = {}

for vm in results:
    region, name, cpu, ram, arch = vm

    image_sku = (
        "12-gen2" if arch.lower() == "x64"
        else "12-arm64"
    )

    urn = f"Debian:debian-12:{image_sku}:latest"
    key = (region, arch)

    if key not in images:
        try:
            az("vm", "image", "show",
               "--location", region, "--urn", urn)
            images[key] = True
        except Exception:
            images[key] = False

    if images[key]:
        recommended = vm
        break

if not recommended:
    raise SystemExit(
        "\nModelos encontrados, mas a imagem Debian "
        "nao pôde ser confirmada."
    )

region, name, cpu, ram, arch = recommended

print("\n" + "=" * 60)
print("CONFIGURACAO RECOMENDADA PARA O PORTAL AZURE")
print("=" * 60)
print("Regiao:          ", region)
print("Tamanho:         ", name)
print("Processador:     ", cpu, "vCPUs")
print("Memoria:         ", ram, "GB")
print("Arquitetura:     ", arch)
print("Imagem:           Debian 12 Bookworm Gen2")
print("Seguranca:        Standard")
print("Redundancia:      Nenhuma")
print("Zona:             Nenhuma")
print("Azure Spot:       Desativado")
print("Disco:            Standard SSD")
print("Autenticacao:     Chave SSH")
print("=" * 60)
print("Diagnostico concluido. Nenhuma VM foi criada.")
PY
