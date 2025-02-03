import xml.etree.ElementTree as ET

# Name: markdown_generator_Hand.py
# Author: Landan
# Purpose: Script to convert NMAP xml output to markdown

def parse_nmap_to_markdown(xml_string):
    tree = ET.ElementTree(ET.fromstring(xml_string))
    root = tree.getroot()

    markdown = []
    
    # Add NMAP Scan Title
    markdown.append("# Nmap Scan Report\n")

    # Process each host in the scan
    for host in root.findall('host'):
        # Get host status (up/down)
        status = host.find('status')
        if status is not None:
            markdown.append(f"**Host Status**: {status.attrib['state']}\n")
        
        # Get host IP address
        address = host.find('address')
        if address is not None:
            ip = address.attrib['addr']
            markdown.append(f"**Host IP**: {ip}\n")
        
        # Get hostnames (if available)
        hostnames = host.find('hostnames')
        if hostnames is not None:
            for hostname in hostnames.findall('hostname'):
                hostname_name = hostname.attrib['name']
                markdown.append(f"**Hostname**: {hostname_name}\n")
        
        # Process Ports and Services with Checkboxes
        ports = host.find('ports')
        if ports is not None:
            markdown.append("### Open Ports and Services\n")
            for port in ports.findall('port'):
                portid = port.attrib['portid']
                protocol = port.attrib['protocol']
                state = port.find('state')
                service = port.find('service')

                if state is not None and state.attrib['state'] == 'open':
                    # Add a checkbox for the open port
                    checkbox = "- [ ]"
                    markdown.append(f"{checkbox} **Port**: {portid}/{protocol}")
                    if service is not None and 'name' in service.attrib:
                        markdown.append(f" - **Service**: {service.attrib['name']}")
                    markdown.append("\n")
        
        # Add a separator between hosts
        markdown.append("\n---\n")

    return ''.join(markdown)

def convert_nmap_xml_to_markdown(input_file, output_file):
    # Read the XML
    with open(input_file, 'r') as file:
        xml_string = file.read()

    # Convert NMAP XML to Markdown
    markdown_content = parse_nmap_to_markdown(xml_string)

    # Write the resulting markdown to an output file
    with open(output_file, 'w') as file:
        file.write(markdown_content)
    
    print(f"Conversion complete! The markdown file is saved as {output_file}")


if __name__ == "__main__":
    # Example usage:
    input_file = 'nmap.xml'  # Path of NMAP XML file
    output_file = 'nmap_scan.md'  # Path of the output file

    convert_nmap_xml_to_markdown(input_file, output_file)
