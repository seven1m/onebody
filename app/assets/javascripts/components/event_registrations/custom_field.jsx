class CustomField extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
    }
  }

  render() {
    return (
      <div>
        <h3>{this.props.name}</h3>
        <p>{this.props.description}</p>
        stuff
      </div>
    )
  }

  //handleSomething(e) {
    //const { value } = e.target
    //this.setState({ value })
  //}
}

window.EventRegistrations = window.EventRegistrations || {}
window.EventRegistrations.CustomField = CustomField
