Steps to install nix on Proxmox: (with quotes from Grok)

Create the nixbld Group
- the automated installer doesn't do this properly on Proxmox

Log in to your Proxmox host as root (via SSH or console).

Add the nixbld group:

groupadd -r nixbld

-r makes it a system group, which is what Nix expects.

Create nixbld Users

Nix typically creates 10 build users (nixbld1 through nixbld10) by default. You can adjust this later, but let’s set up a few for now:

for i in {1..10}; do
  useradd -r -g nixbld -d /var/empty -s /sbin/nologin -c "Nix build user $i" nixbld$i
done

-r: System user.
-g nixbld: Assigns them to the nixbld group.
-d /var/empty: No home directory.
-s /sbin/nologin: Prevents login.
-c: Comment for clarity.

Add nixbld users to nixbld group, manually because standard command fails to add them to group
- modify line in /etc/passwd file describing members of nixbld
- group number might not be 997 on your system

nixbld:x:997:nixbld1,nixbld2,nixbld3,nixbld4,nixbld5,nixbld6,nixbld7,nixbld8,nixbld9,nixbld10

- I didn't need to modify /etc/group but this might be because commands I used to modify group membership might have done this already, while failing to change /etc/passwd file. You might need to edit /etc/group as follows:

nixbld:x:997:nixbld1,nixbld2,nixbld3,nixbld4,nixbld5,nixbld6,nixbld7,nixbld8,nixbld9,nixbld10


Create nix directory with correct permissions

-part of the automated installation process, but since that doesn't work well on Proxmox, will be done here in preparation

mkdir -p /nix
chown root:root /nix
chmod 755 /nix

Standard installation instructions require curl, thus we install

apt install curl -y

Run the official Nix installer as root:

sh <(curl -L https://nixos.org/nix/install) --no-daemon

After installation, load Nix into your current shell:

. /root/.nix-profile/etc/profile.d/nix.sh

To make this persistent, add it to your ~/.bashrc or ~/.profile:

echo '. /root/.nix-profile/etc/profile.d/nix.sh' >> /root/.bashrc

Verify Installation:
Check that Nix is working:

nix --version
You should see something like nix (Nix) 2.20.0 (version as of April 2025 may vary).

Optional: Install a Package to Test:

Try installing something simple:

nix-env -iA nixpkgs.hello

Run it:

hello

Output should be: Hello, world!
