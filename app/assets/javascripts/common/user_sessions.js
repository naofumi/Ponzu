onDomReady(function(){
	var showPasswordToggle = document.getElementById('show_password');
	if (showPasswordToggle) {
		kss.addEventListener(showPasswordToggle, 'change', function(event){
			var newType = showPasswordToggle.checked ? 'text' : 'password';
			document.getElementById('user_session_password').type = newType;
		})
	}
	return true;
})
