package sendEmail.function;


import com.microsoft.azure.functions.ExecutionContext;
import com.microsoft.azure.functions.HttpMethod;
import com.microsoft.azure.functions.HttpRequestMessage;
import com.microsoft.azure.functions.HttpResponseMessage;
import com.microsoft.azure.functions.HttpStatus;
import com.microsoft.azure.functions.annotation.AuthorizationLevel;
import com.microsoft.azure.functions.annotation.FunctionName;
import com.microsoft.azure.functions.annotation.HttpTrigger;


import javax.mail.*;
import javax.mail.internet.*;
import java.util.Optional;
import java.util.Properties;
import java.util.logging.Logger;


/**
 * Azure Function para envio de emails
 */
public class EmailFunction {
   
    private static final String SMTP_HOST = "smtp.gmail.com";
    private static final String SMTP_PORT = "587";
   
    @FunctionName("SendEmail")
    public HttpResponseMessage sendEmail(
            @HttpTrigger(
                name = "req",
                methods = {HttpMethod.POST},
                authLevel = AuthorizationLevel.FUNCTION)
                HttpRequestMessage<Optional<EmailRequest>> request,
            final ExecutionContext context) {
       
        Logger logger = context.getLogger();
        logger.info("Processando requisição de envio de email");


        try {
            // Obter dados da requisição
            Optional<EmailRequest> emailRequestOpt = request.getBody();
            if (!emailRequestOpt.isPresent()) {
                return request.createResponseBuilder(HttpStatus.BAD_REQUEST)
                    .body(new EmailResponse(false, "Corpo da requisição é obrigatório"))
                    .build();
            }


            EmailRequest emailRequest = emailRequestOpt.get();
           
            // Validar campos obrigatórios
            if (emailRequest.getTo() == null || emailRequest.getTo().trim().isEmpty()) {
                return request.createResponseBuilder(HttpStatus.BAD_REQUEST)
                    .body(new EmailResponse(false, "Campo 'to' é obrigatório"))
                    .build();
            }
           
            if (emailRequest.getSubject() == null || emailRequest.getSubject().trim().isEmpty()) {
                return request.createResponseBuilder(HttpStatus.BAD_REQUEST)
                    .body(new EmailResponse(false, "Campo 'subject' é obrigatório"))
                    .build();
            }
           
            if (emailRequest.getBody() == null || emailRequest.getBody().trim().isEmpty()) {
                return request.createResponseBuilder(HttpStatus.BAD_REQUEST)
                    .body(new EmailResponse(false, "Campo 'body' é obrigatório"))
                    .build();
            }


            // Obter configurações do ambiente
            String fromEmail = System.getenv("EMAIL_FROM");
            String emailPassword = System.getenv("EMAIL_PASSWORD");
           
            if (fromEmail == null || emailPassword == null) {
                logger.severe("Configurações de email não encontradas nas variáveis de ambiente");
                return request.createResponseBuilder(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new EmailResponse(false, "Configurações de email não encontradas"))
                    .build();
            }


            // Configurar propriedades SMTP
            Properties props = new Properties();
            props.put("mail.smtp.auth", "true");
            props.put("mail.smtp.starttls.enable", "true");
            props.put("mail.smtp.host", SMTP_HOST);
            props.put("mail.smtp.port", SMTP_PORT);
            props.put("mail.smtp.ssl.trust", SMTP_HOST);


            // Criar sessão
            Session session = Session.getInstance(props, new Authenticator() {
                @Override
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication(fromEmail, emailPassword);
                }
            });


            // Criar mensagem
            Message message = new MimeMessage(session);
            message.setFrom(new InternetAddress(fromEmail));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(emailRequest.getTo()));
            message.setSubject(emailRequest.getSubject());
            message.setText(emailRequest.getBody());


            // Enviar email
            Transport.send(message);
           
            logger.info("Email enviado com sucesso para: " + emailRequest.getTo());
           
            return request.createResponseBuilder(HttpStatus.OK)
                .body(new EmailResponse(true, "Email enviado com sucesso"))
                .build();
               
        } catch (MessagingException e) {
            logger.severe("Erro ao enviar email: " + e.getMessage());
            return request.createResponseBuilder(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new EmailResponse(false, "Erro ao enviar email: " + e.getMessage()))
                .build();
        } catch (Exception e) {
            logger.severe("Erro inesperado: " + e.getMessage());
            return request.createResponseBuilder(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new EmailResponse(false, "Erro interno do servidor"))
                .build();
        }
    }
   
    // Classe para requisição de email
    public static class EmailRequest {
        private String to;
        private String subject;
        private String body;
       
        public EmailRequest() {}
       
        public EmailRequest(String to, String subject, String body) {
            this.to = to;
            this.subject = subject;
            this.body = body;
        }
       
        public String getTo() { return to; }
        public void setTo(String to) { this.to = to; }
       
        public String getSubject() { return subject; }
        public void setSubject(String subject) { this.subject = subject; }
       
        public String getBody() { return body; }
        public void setBody(String body) { this.body = body; }
    }
   
    // Classe para resposta de email
    public static class EmailResponse {
        private boolean success;
        private String message;
       
        public EmailResponse() {}
       
        public EmailResponse(boolean success, String message) {
            this.success = success;
            this.message = message;
        }
       
        public boolean isSuccess() { return success; }
        public void setSuccess(boolean success) { this.success = success; }
       
        public String getMessage() { return message; }
        public void setMessage(String message) { this.message = message; }
    }
}

