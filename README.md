How to Compile
===============

Download docbook xsl from [docbook-xsl-1.78.1](http://sourceforge.net/projects/docbook/files/docbook-xsl/1.78.1/)

Assuming xmlproc tool is available in your path, from the root directory of openstack-content project run

```bash
xsltproc --xinclude --nonet ../docbook-xsl-1.78.1/html/docbook.xsl openstack.xml > output/public/openstack.html
```

Output html file is openstack.html in folder `output/public/openstack.html`

