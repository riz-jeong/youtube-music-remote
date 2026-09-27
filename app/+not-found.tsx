import { Link } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { StyleSheet, Text, View } from 'react-native';
import { Appbar } from 'react-native-paper';

export default function NotFoundScreen() {
  const { t } = useTranslation('translation', { keyPrefix: 'notFound' });

  return (
    <>
      <Appbar.Header>
        <Appbar.Content title={t('title')} />
      </Appbar.Header>
      <View style={styles.container}>
        <Text>{t('message')}</Text>
        <Link href='/' style={styles.link}></Link>
      </View>
    </>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  link: {
    marginTop: 15,
    paddingVertical: 15,
  },
});
