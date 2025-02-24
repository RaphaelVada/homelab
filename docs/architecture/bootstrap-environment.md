>> This is just my personal setup. I just want to present my bootstraping and give others an example how they could setup something like this. The decissions also reflect my learning processes and reasoning. So this is not supposed to be a template project.

# Bootstrap Enviroment

The bootstrap environment serves a dual purpose in this homelab setup: It acts both as a workbench for infrastructure management and as a bootstrapping tool for initial setup and ongoing maintenance. This approach ensures a consistent, secure, and portable environment for managing the homelab infrastructure.

## Dual Nature: Workbench & Bootstrap

### Workbench Capabilities
- Development environment for infrastructure code
- Central point for tool access and configuration
- Secure handling of credentials and secrets
- Documentation and planning environment

### Bootstrap Functions
- Initial infrastructure setup
- Configuration deployment
- System recovery procedures
- Ongoing maintenance operations

### Key Benefits

1. **Portability**
   - Minimal host requirements (only Docker/Docker Compose)
   - Consistent environment across different workstations
   - Optional VS Code integration, but not dependent on it
   - Works on any system that can run containers

2. **Security**
   - Centralized secret management with Vault
   - RAM-disk based secrets handling
   - Encrypted configuration storage
   - Isolated environment for sensitive operations

3. **Reproducibility**
   - Version-controlled infrastructure configuration
   - Documented processes and procedures
   - Automated setup and maintenance scripts
   - Consistent tool versions across setups

## Personal requirements

Currently i build up a homelab environment on multiple layers: bare metal thin clients/nas-storage, virtualization and containerization. My main goals are:
- making it robust & repeatable
- get to the containerization layer as easy as possible (This is the layer where i mainliy want to play arround)

So i come from: 
- setting up vms with cloud-init templates within proxmox
- installing docker in vms and run containers based on docker compose on it
- separating the compute and data layer

## Architecture

### Component Overview

1. **Core Container Environment**
   - Base container with essential tools
   - Independent of specific IDE/editor
   - Self-contained CLI tooling
   - Integrated secret management

2. **Integration Layer**
   - VS Code Dev Container support
   - Terminal-based access
   - Documentation tools (PlantUML, Markdown)
   - Flexible access methods

3. **Tool Suite**
   - Kubernetes tools (kubectl, helm, talosctl)
   - Infrastructure management (Proxmox CLI, Ansible)
   - Security tools (Vault)
   - Documentation generators


## Desissions

This are the decissions I made

### ADR: Deployment of Bootstrap enviroment

**tl;dr: Designed to be deployed as "dev container" based on vscode to workstation (PC, Laptop). Still not sure about the vscode dependency, but it will be the workhorse (I will keep it for now)**

So currently I have 3 PCs (my PC, HTPC, family Laptop), where I want to work from. On this machines I play around with different operation Systems and setups. So I need to reduce the number of parts installed on these machines.

My first thought was, to put an adittional VM/Container to my virtualization layer so I could SSH into it. But thus it is depentent on the availability of the virtualization enviroment. So this also needs an life access control layer. To keep this part reproducable I would need to make this setup as portable as possible.

So in the end I decided to utize dev containers. I also want to play arround with vs code dev containers. So I think this is the perfect match. It still needs to be installed on each PC. But it comes as a personal bundle of tools.

What I am not sure about is, if I really want to rely on microsoft vs-code. I really love the modularity of vs code and the fact that with the dev container i can also provide a vs code plugin bundle. So besides CLI Tools I have aditional UI tools in VS Code. In the end VS Code is a Code Editor/IDE. I would prefer something more losely coupled, which I could spin up without vs code and connect to the terminal in any way I want. This is definitivly possible with some work. In the end, vs code is still my go to working tool. So I keep the dev container setup and just ditch the optimized templates for vs code dev containers and build my own ones to keep control over the base image.

### ADR: Project Structure

- Include Documentation and reasoning within the project
- Folders for configuring the Bootstrap enviroment itself
- Folders for Architecture Layers / Tools
- Secrets are stored outside of git-repo and will be mounted into the dev container
    - Will also include most networking part
    - Maybe will also cause to place some configuration examples into this project

### ADR: Tooling - Terraform | CLI Collection | Ansible

**tl;dr: Discarded ~~terraform~~ , Using CLI Tools and still keeping Ansible(not sure)**

#### Terraform

- Adapter for Proxmox is Community driven and feature incomplete
    - Declarative Approach doesn't work propperly
    - A lot of work is required for preparation and cleanup within proxmox
- Learning terraform propperly doesn't pay off
    - With templates it's not much work to set up a vm and keep notes of the setup to reproduce it
    - Complexity and Change rate within the homelab is low

I played arround setting up terraform. I got to the point, where I setted up vms within proxmox. So in terraform you need to have an adapter for each infrastructure provider. For proxmox there is no official provider, just an community provider. This community provider unfortunatly doesn't cover the full declarative approach. Sometimes its necessary, to prepare things within proxmox or clean up afterwards. Still the main work to spin up a new vm was to prepare a cloud-init ready template first within proxmox, before running terraform. So also terraform is still a new declaration language i needed to learn. I felt like looking up the according terraform features for the adapter with the risk of not working propperly is more work than just configuring it by hand within the gui. so this is just the vm part. But to work properly with terraform I also need to integrate the networking layer into it. So this means: also integrating network components like routers, dns servers, etc. 

To be clear: I still think, that terraform is a great tool. Especially in a setup of cloud-hyperscalers. It just don't pay off in my usecase.

#### Ansible

- I love the agnostic approach: Doing everything to SSH
    - Using Linux native tools
- It's not declarative by default
- Maybe doesn't work for everything. Talos OS doesn't come with SSH on purpose.

So I just played arround with terraform to adapt some templates to setup an RKE2 Kubernetes cluster. I loved that everything runs through SSH and setup SSH-Keys. The Playbooks for RKE2 Setup were easy to reproduce and adapt to my homelab. Even fixed a few semantic issues within the roles, to make setup easier. So I see high potential for me. Still not sure, if my usage will be heavy enough to pay off. In the case of the K8s setup I just switched to the Talos OS distribution. This needs to be setup through the API and is designed to not have ssh access for security reasons.


#### CLI Collection

- CLI Tools are still the way to go for some things (e.g. kubectl)
- Vendor Specific
- Can be easly use in combination with local scripts
- Common pattern: CLI connects to an API and Authenticating with an Secret key. Trying to be as declarative as possible
- Influences the Design of the bootstrap system

So my latest decission on my homelab was to switch to Talos OS. This also means, that I either should use something like terraform or use their CLI tool directly. Looking arround for my proxmox setup also reveals, that I cloud use a proxmox CLI tool. Till now I used the webgui.

So the most tools work like following: Connecting to the service and tell them the desired state. Thus you have following components
- CLI Tool
- access secret, mostly in separate files
- some files describing the desired state / list of imperative commands

