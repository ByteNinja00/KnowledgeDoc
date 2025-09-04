# configMap对象

configMap存储让其它对象可引用其配置的API对象。有两个字段**data**和**binaryData**。

- data：用来保存UTF-8字符串。
- binaryData：用来保存二进制数据作为base64编码的字串。

binaryData用得比较少，这里主要理解**data**字段。