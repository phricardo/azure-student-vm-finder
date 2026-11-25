# Azure Student VM Finder

[English](#english) · [Português (Brasil)](#portugues-brasil)

<a id="english"></a>

## English

Find eligible Azure VM sizes for a Debian 12 lab using your Azure for Students subscription. The script checks regional restrictions, vCPU quotas, and Debian image availability, then prints a recommended configuration. It does not create a VM.

### Open Azure Cloud Shell and run the script

1. Sign in to the [Azure portal](https://portal.azure.com/) with the account linked to your Azure for Students subscription.
2. Select the Cloud Shell terminal icon (`>_`) in the top bar. You can also [open Cloud Shell directly](https://shell.azure.com/).
3. Select **Bash**. If the terminal opens in PowerShell, use the shell selector to switch to **Bash**.
4. If the setup panel appears, select **No storage account required**, choose **Azure for Students** under **Subscription**, and leave **Private virtual network** unchecked if shown. Select **Apply** to start a temporary session. [Microsoft Learn guide with screenshots](https://learn.microsoft.com/en-us/azure/cloud-shell/get-started/ephemeral)
5. Once the Bash prompt appears, open [the English script](azure-vm-finder.sh) on GitHub, select **Raw**, and copy the entire file through the final `PY` line. Paste it into Bash, press **Enter**, and wait for the command to finish. Cloud Shell runs in your browser, so you can use it without installing Azure CLI or Python on your computer.

If you have multiple subscriptions, run `az account show --query name -o tsv` before pasting the script. If it shows a different subscription, run `az account set --subscription "Azure for Students"`.

### Use the recommendation in the Azure portal

Find **RECOMMENDED AZURE PORTAL CONFIGURATION** at the end of the output. In the portal, open **Virtual machines**, choose **Create**, then **Azure virtual machine**. Use the values from your run.

| Script output | Where to use it |
| --- | --- |
| Region, VM Size, Architecture, Image | **Basics** → **Region**, **Size**, **VM architecture**, and **Image**. Choose the Debian 12 Bookworm Gen2 image for the reported architecture. Processor and memory are properties of the selected size. |
| Security Type, Availability, Availability Zone, Azure Spot | **Basics** → **Security type** (Standard), **Availability options** (No infrastructure redundancy required), and the Azure Spot option (off). Leave the zone unset. |
| Disk Type | **Disks** → select **Standard SSD** for the OS disk. |
| Authentication | **Basics** → **Administrator account** → **SSH public key**. |

To create the VM manually, follow the [Microsoft Learn guide to creating a Linux VM in the Azure portal](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-portal). Use the Debian image from your result when choosing the image.

<a id="portugues-brasil"></a>

## Português (Brasil)

Encontre tamanhos de VM elegíveis para um laboratório com Debian 12 na sua assinatura Azure for Students. O script verifica as restrições de região, as cotas de vCPU e a disponibilidade da imagem Debian e exibe uma configuração recomendada. Ele não cria a VM.

### Como acessar o Azure Cloud Shell e executar o script

1. Entre no [Portal do Azure](https://portal.azure.com/) com a conta vinculada à sua assinatura Azure for Students.
2. Clique no ícone de terminal (`>_`) do Cloud Shell na barra superior. Você também pode [abrir o Cloud Shell diretamente](https://shell.azure.com/).
3. Selecione **Bash**. Se o terminal abrir em PowerShell, use o seletor do terminal para trocar para **Bash**.
4. Se o painel de configuração aparecer, marque **Nenhuma conta de armazenamento necessária**, escolha **Azure for Students** em **Assinatura** e deixe **Rede virtual privada** desmarcada, caso apareça. Clique em **Aplicar** para iniciar uma sessão temporária. [Guia do Microsoft Learn com capturas de tela](https://learn.microsoft.com/pt-br/azure/cloud-shell/get-started/ephemeral)
5. Quando o prompt do Bash aparecer, abra [o script em português](azure-vm-finder-ptbr.sh) no GitHub, clique em **Raw** e copie todo o conteúdo até a última linha, `PY`. Cole no Bash, pressione **Enter** e aguarde o comando terminar. O Cloud Shell funciona no navegador, sem instalar a CLI do Azure ou o Python no seu computador.

Se você tiver mais de uma assinatura, rode `az account show --query name -o tsv` antes de colar o script. Se aparecer outra assinatura, rode `az account set --subscription "Azure for Students"`.

### Como usar o resultado no Portal do Azure

Procure **CONFIGURACAO RECOMENDADA PARA O PORTAL AZURE** no fim da saída. No portal, abra **Máquinas virtuais**, clique em **Criar** e escolha **Máquina virtual do Azure**. Use os valores da sua execução.

| Saída do script | Onde preencher |
| --- | --- |
| Região, Tamanho, Arquitetura, Imagem | Guia **Básico** → **Região**, **Tamanho**, **Arquitetura da VM** e **Imagem**. Escolha o Debian 12 Bookworm Gen2 para a arquitetura indicada. Processador e memória são características do tamanho selecionado. |
| Segurança, Redundância, Zona, Azure Spot | Guia **Básico** → **Tipo de segurança** (Standard), **Opções de disponibilidade** (Nenhuma redundância de infraestrutura necessária) e opção Azure Spot (desativada). Deixe a zona sem seleção. |
| Disco | Guia **Discos** → selecione **SSD Standard** para o disco do sistema operacional. |
| Autenticação | Guia **Básico** → **Conta de administrador** → **Chave pública SSH**. |

Para criar a VM manualmente, siga o [guia do Microsoft Learn para criar uma VM Linux no Portal do Azure](https://learn.microsoft.com/pt-br/azure/virtual-machines/linux/quick-create-portal). Na escolha da imagem, use a versão do Debian indicada no resultado.
