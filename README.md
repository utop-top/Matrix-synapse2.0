说明：你需要准备解析的域名
auth.example.com   mas身份验证服务器
example.com   synapse服务器域名及服务名称

下面是ele-hq服务(element-web,element-call)
app.example.com    element-web服务域名
call.example.com   element-call服务域名
jwt.example.com  
livekit.examle.com


你需要调整的文件
nginx中的域名
mas config中的配置及域名
home文件中的配置
element-call 与elment-web配置文件修改

注意：示例example.com 为synapse 服务域名地址倘若你改为 matrix.example.com 那么所有的配置文件中的example.com都要改为matrix.example.com其它域名以此类推
