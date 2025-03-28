<html>
    <head>
        <title>Simple-Api-Jean</title>
    </head>
    <body>
        <h1>Student Checking App</h1>
        <form action="" method="POST">
            <button type="submit" name="submit">List Student</button>
        </form>

        <?php
        if ($_SERVER['REQUEST_METHOD'] == "POST" && isset($_POST['submit'])) {
            $username = getenv('USERNAME') ?: 'fake_username';
            $password = getenv('PASSWORD') ?: 'fake_password';
            //$api_url = getenv('API_URL') ?: 'http://<name_container_simple-api-jean:port>';
            $api_url = getenv('API_URL') ?: 'http://workspace-service-simple-api-jean-1:5000';

            $context = stream_context_create([
                "http" => [
                    "header" => "Authorization: Basic " . base64_encode("$username:$password"),
                ]
            ]);

            $url = "$api_url/simple-jean/api/v1.0/get_student_ages";
            $response = @file_get_contents($url, false, $context);

            if ($response === FALSE) {
                echo "<p style='color:red;'>Erreur : Impossible de récupérer les données.</p>";
            } else {
                $list = json_decode($response, true);
                echo "<p style='color:blue;'>Liste des étudiants :</p>";
                foreach ($list["student_ages"] as $key => $value) {
                    echo "- $key a $value ans <br>";
                }
            }
        }
        ?>
    </body>
</html>
