// Button component
export function Component() {
  return 'button';
}

// Adding some lines to test line counting
const styles = {
  button: {
    padding: '10px',
    margin: '5px'
  }
};

function handleClick() {
  console.log('clicked');
}

export { handleClick, styles };